using afConcurrent::SynchronizedState
using concurrent::ActorPool
using concurrent::Future
using util::PathEnv

** Adapted from 'draft'
internal const class AppRestarter {
	private const static Log 		log 		:= Utils.getLog(AppRestarter#)
	private const SynchronizedState	conState
	
	const Str	appName
	const Int 	appPort
	const Str	params
	
	new make(BedSheetBuilder bob, Int appPort) {
		this.appName 		= bob.appName
		this.appPort 		= appPort
		this.params			= bob.toStringy
		// as we're not run inside afIoc, we don't have ActorPools
		this.conState		= SynchronizedState(ActorPool(), AppRestarterState#)
	}

	Void initialise() {
		withState |state| {
			if (state.realWebApp == null) {
				state.updateTimeStamps
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
				state.launchWebApp(appName, appPort, params)
				state.updateTimeStamps
			}
			return modified
		}.get(30sec)
	}
	
	Void forceRestart() {
		withState |state->Obj?| {
			state.killWebApp(appName)
			state.launchWebApp(appName, appPort, params)
			state.updateTimeStamps
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

	Void updateTimeStamps() {
		// BugFix: Pod.list throws an Err if any pod is invalid (wrong dependencies etc) 
		// this way we don't even load the pod into memory!
		Env.cur.findAllPodNames.each |podName| {
			podTimeStamps[podName] = podFile(podName).modified
		}
		
		log.info(BsLogMsgs.appRestarter_cachedPodTimestamps(podTimeStamps.size))
	}
	
	Bool podsModified()	{
		true == Env.cur.findAllPodNames.eachWhile |podName| {
			if (podTimeStamps.containsKey(podName)) {
				if (podFile(podName).modified > podTimeStamps[podName]) {
					log.info(BsLogMsgs.appRestarter_podUpdatd(podName, podTimeStamps[podName] - podFile(podName).modified))
					return true
				}
			} else {
				podTimeStamps[podName] = podFile(podName).modified
				log.info(BsLogMsgs.appRestarter_podFound(podName))
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
	
	private File podFile(Str podName) {
		Env.cur.findPodFile(podName)
	}
}
