using afConcurrent::SynchronizedState
using concurrent::ActorPool
using concurrent::Future
using util::PathEnv

** Originally adapted from 'draft'
internal const class AppRestarter {
	private const static Log 		log 		:= Utils.getLog(AppRestarter#)
	private const SynchronizedState	conState
	
	const Str?	appPod
	const Str	appName
	const Int 	appPort
	const Str	params
	
	new make(BedSheetBuilder bob, Int appPort, Bool watchAllPods) {
		this.appName 	= bob.appName
		this.appPort 	= appPort
		this.appPod		= watchAllPods ? null : ((Pod) bob.options[BsConstants.meta_appPod]).name
		this.params		= bob.toStringy
		// as we're not run inside afIoc, we don't have ActorPools
		this.conState	= SynchronizedState(ActorPool(), AppRestarterState#)
	}

	Void initialise() {
		withState |state| {
			if (state.realWebApp == null) {
				state.loadTimeStamps(appPod)
				state.launchWebApp(appName, appPort, params)
			}
		}
	}

	** Check if pods have been modified.
	Bool checkPods() {
		withState |state->Bool| {
			modified := state.podsModified 
			if (modified) {
				state.killWebApp(appName)
				state.loadTimeStamps(appPod)
				state.launchWebApp(appName, appPort, params)
			}
			return modified
		}.get(30sec)
	}
	
	Void forceRestart() {
		withState |state->Obj?| {
			state.killWebApp(appName)
			state.loadTimeStamps(appPod)
			state.launchWebApp(appName, appPort, params)
			return null
		}.get(30sec)		
	}
	
	private Future withState(|AppRestarterState| state) {
		conState.withState(state)
	}
}

internal class AppRestarterState {
	private const static Log log := Utils.getLog(AppRestarter#)
	
	Str:DateTime?	podTimeStamps	:= [:]
	Process?		realWebApp

	// BugFix: Pod.list throws an Err if any pod is invalid (wrong dependencies etc) 
	// this way we don't even load the pod into memory!
	Void loadTimeStamps(Str? appPod) {
		podTimeStamps = Str:DateTime?[:]
		pods := appPod == null ? Env.cur.findAllPodNames : findAllPodNames(appPod, Str[,])
		pods.each |podName| {
			podTimeStamps[podName] = podFile(podName).modified
		}
		
		log.info(BsLogMsgs.appRestarter_cachedPodTimestamps(podTimeStamps.size))
	}

	Bool podsModified()	{
		true == podTimeStamps.keys.eachWhile |podName| {
			podFile := podFile(podName)
			if (podFile == null)
				return true	// who deleted my pod!?

			if (podFile.modified > podTimeStamps[podName]) {
				log.info(BsLogMsgs.appRestarter_podUpdatd(podName, DateTime.now - podFile.modified))
				return true
			}

			return null
		}
	}
	
	Void launchWebApp(Str appName, Int appPort, Str params) {
		log.info(BsLogMsgs.appRestarter_lauchingApp(appName, appPort))
		try {
			home	:= Env.cur.homeDir.normalize
			sysjar	:= home + `lib/java/sys.jar`
			
			args := ["java", "-cp", sysjar.osPath, "-Dfan.home=${home.osPath}", "fanx.tools.Fan", MainProxied#.qname, params]
			
			log.info(BsLogMsgs.appRestarter_process(args.join(" ")))
			realWebApp = Process(args).run
		} catch (Err err)
			throw BedSheetErr(BsErrMsgs.appRestarter_couldNotLaunch(appName), err)
	}

	Void killWebApp(Str appName)	{
		if (realWebApp == null)
			return
		log.info(BsLogMsgs.appRestarter_killingApp(appName))
		realWebApp.kill
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
		zip		  := Zip.read(podFile.in(4096))
		metaProps := ([Str:Str]?) null
		try {
			File? entry
			while (metaProps == null && (entry = zip.readNext) != null) {
				if (entry.uri == `/meta.props`)
					metaProps = entry.readProps				
			}
		} finally {
			zip.close
		}
		
		if (metaProps == null) {
			log.warn(BsLogMsgs.appRestarter_noMetaProps(podFile))
			return Str#.emptyList
		}
		
		return metaProps["pod.depends"].split(';').map { it.isEmpty ? null : Depend(it).name }.exclude { it == null }
	}
}
