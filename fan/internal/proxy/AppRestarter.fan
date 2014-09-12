using afConcurrent::SynchronizedState
using concurrent::ActorPool
using concurrent::Future
using util::PathEnv

** Adapted from 'draft'
internal const class AppRestarter {
	private const static Log 		log 		:= Utils.getLog(AppRestarter#)
	private const SynchronizedState	conState
	
	const Str 	appModule
	const Int 	appPort
	const Int 	proxyPort
	const Bool	noTransDeps
	const Str?	env
	
	new make(Str appModule, Int appPort, Int proxyPort, Bool noTransDeps, Str? env) { 
		this.appModule 		= appModule
		this.appPort 		= appPort
		this.proxyPort		= proxyPort
		this.noTransDeps	= noTransDeps
		this.env			= env
		// as we're not run inside afIoc, we don't have ActorPools
		this.conState		= SynchronizedState(ActorPool(), AppRestarterState#)
	}

	Void initialise() {
		withState |state| {
			if (state.realWebApp == null) {
				state.updateTimeStamps
				state.launchWebApp(appModule, appPort, proxyPort, noTransDeps, env)
			}
		}
	}

	** Check if pods have been modified.
	Bool checkPods() {
		withState |state->Bool| {
			modified := state.podsModified 
			if (modified) {
				state.killWebApp(appModule)
				state.launchWebApp(appModule, appPort, proxyPort, noTransDeps, env)
				state.updateTimeStamps
			}
			return modified
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
			if (podFile(podName).modified > podTimeStamps[podName]) {
				log.info(BsLogMsgs.appRestarter_podUpdatd(podName, podTimeStamps[podName] - podFile(podName).modified))
				return true
			}
			return null
		}
	}
	
	Void launchWebApp(Str appModule, Int appPort, Int proxyPort, Bool noTransDeps, Str? env) {
		log.info(BsLogMsgs.appRestarter_lauchingApp(appModule, appPort))
		try {
			home	:= Env.cur.homeDir.normalize
			sysjar	:= home + `lib/java/sys.jar`
			
			args := ["java", "-cp", sysjar.osPath, "-Dfan.home=${home.osPath}", "fanx.tools.Fan", MainProxied#.qname, "-pingProxy", "-pingProxyPort", proxyPort.toStr, appModule, appPort.toStr]
			
			if (env != null) {
				args.insert(-2, "-env")
				args.insert(-2, env)
			}
			
			if (noTransDeps)
				args.insert(-2, "-noTransDeps")
			
			log.info(BsLogMsgs.appRestarter_process(args.join(" ")))
			realWebApp = Process(args).run
		} catch (Err err)
			throw BedSheetErr(BsErrMsgs.appRestarter_couldNotLaunch(appModule), err)
	}

	Void killWebApp(Str appModule)	{
		if (realWebApp == null)
			return
		log.info(BsLogMsgs.appRestarter_killingApp(appModule))
		realWebApp.kill
	}
	
	private File podFile(Str podName) {
		Env.cur.findPodFile(podName)
	}
}
