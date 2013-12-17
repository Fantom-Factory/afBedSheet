using afIoc::ConcurrentState
using concurrent::Actor
using concurrent::Future
using util::PathEnv

** Adapted from 'draft'
internal const class AppRestarter {
	private const static Log 		log 		:= Utils.getLog(AppRestarter#)
	private const ConcurrentState 	conState	:= ConcurrentState(AppRestarterState#)
	
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
		Env.cur().findAllPodNames.each |podName| {
			podTimeStamps[podName] = podFile(podName).modified
		}
		
		log.info(BsLogMsgs.appRestarterCachedPodTimestamps(podTimeStamps.size))
	}
	
	Bool podsModified()	{
		true == Env.cur.findAllPodNames.eachWhile |podName| {
			if (podFile(podName).modified > podTimeStamps[podName]) {
				log.info(BsLogMsgs.appRestarterPodUpdatd(podName, podTimeStamps[podName] - podFile(podName).modified))
				return true
			}
			return null
		}
	}
	
	Void launchWebApp(Str appModule, Int appPort, Int proxyPort, Bool noTransDeps, Str? env) {
		log.info(BsLogMsgs.appRestarterLauchingApp(appModule, appPort))
		home := Env.cur.homeDir.osPath
		deps := noTransDeps ? "-noTransDeps " : "" 
		envS := (env == null) ? "" : "-env ${env} "
		args := "java -cp \"${home}/lib/java/sys.jar\" -Dfan.home=\"${home}\" fanx.tools.Fan afBedSheet::MainProxied ${envS}-pingProxy -pingProxyPort $proxyPort ${deps}$appModule $appPort"
		log.debug(args)
		realWebApp = Process(args.split).run
	}

	Void killWebApp(Str appModule)	{
		if (realWebApp == null)
			return
		log.info(BsLogMsgs.appRestarterKillingApp(appModule))
		realWebApp.kill
	}
	
	private File podFile(Str podName) {
		Env.cur.findPodFile(podName)
	}	
}
