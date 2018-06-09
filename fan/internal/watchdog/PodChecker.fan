using afConcurrent::SynchronizedState
using concurrent::ActorPool
using concurrent::Future
using util::PathEnv

internal const class PodChecker {
	private const SynchronizedState	state
	private const Bool				watchAllPods
	private const Str				appPod
	
	new make(Str appPod, Bool watchAllPods) {
		// as we're not run inside afIoc, we don't have ActorPools
		this.state			= SynchronizedState(ActorPool(), PodCheckerState#)
		this.watchAllPods	= watchAllPods
		this.appPod			= appPod
	}

	This initialise() {
		async |state| {
			state.loadTimeStamps(watchAllPods ? null : appPod)
		}
		return this
	}

	** Check if pods have been modified.
	Bool podsModifed() {
		async |state->Bool| {
			state.podsModified 
		}.get(12sec)
	}
	
	Str? restartMsg() {
		state->msg
	}
	
	private Future async(|PodCheckerState| fn) {
		state.async(fn)
	}
}

internal class PodCheckerState {
	private const static Log log := Utils.log
	
	Str:DateTime?	podTimeStamps	:= [:]
	Duration?		lastCheck
	Bool?			lastValue
	Str?			msg

	// BugFix: Pod.list throws an Err if any pod is invalid (wrong dependencies etc) 
	// this way we don't even load the pod into memory!
	Void loadTimeStamps(Str? appPod) {
		podTimeStamps = Str:DateTime?[:]
		pods := appPod == null ? Env.cur.findAllPodNames : findAllPodNames(appPod, Str[,])
		pods.each |podName| {
			podTimeStamps[podName] = podFile(podName)?.modified
		}
		lastCheck = Duration.now
		lastValue = false
		
		log.info("Cached the timestamps of ${podTimeStamps.size} pods")
	}

	Bool podsModified()	{
		if ((Duration.now - lastCheck) <= 750ms)
			return lastValue
		
		lastValue = true == podTimeStamps.keys.eachWhile |podName| {
			podFile := podFile(podName)
			if (podFile == null) {
				msg = "Pod '$podName' has been DELETED!?"
				log.info(msg)	// who deleted my pod!?
				return true
			}

			if (podFile.modified > podTimeStamps[podName]) {
				time := (DateTime.now - podFile.modified).toLocale
				msg = "Pod '$podName' pod was updated $time ago."
				log.info(msg)
				return true
			}

			return null
		}
		lastCheck = Duration.now
		return lastValue
	}
	
	private File? podFile(Str podName) {
		Env.cur.findPodFile(podName)
	}
	
	private Str[] findAllPodNames(Str podName, Str[] podNames) {
		podNames.add(podName)
		findPodDependencies(podName).each {
			if (!podNames.contains(it))
				findAllPodNames(it, podNames)
		}
		return podNames
	}
	
	private Str[] findPodDependencies(Str podName) {
		podFile   := podFile(podName)
		
		if (podFile == null) {
			log.warn("Could not find pod file for '$podName'")
			return Str#.emptyList
		}
		
		zip	 := Zip.read(podFile.in(4096))
		meta := ([Str:Str]?) null
		try {
			File? entry
			while (meta == null && (entry = zip.readNext) != null) {
				if (entry.uri == `/meta.props`)
					meta = entry.readProps				
			}
		} finally {
			zip.close
		}
		
		if (meta == null) {
			log.warn("Could not find `meta.props` in ${podFile.normalize}")
			return Str#.emptyList
		}
		
		return meta["pod.depends"].split(';').map { it.isEmpty ? null : Depend(it).name }.exclude { it == null }
	}
}
