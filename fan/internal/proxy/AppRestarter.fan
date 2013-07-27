using afIoc::ConcurrentState
using concurrent::Actor
using concurrent::Future
using util::PathEnv

** Adapted from 'draft'
internal const class AppRestarter {
	private const static Log 		log 		:= Utils.getLog(AppRestarter#)
	private const ConcurrentState 	conState	:= ConcurrentState(AppRestarterState#)
	
	const Str appModule
	const Int appPort
	const Int proxyPort
	
	new make(Str appModule, Int appPort, Int proxyPort) { 
		this.appModule 	= appModule
		this.appPort 	= appPort
		this.proxyPort	= proxyPort
	}

	Void initialise() {
		withState |state| {
			if (state.realWebApp == null) {
				state.updateTimeStamps
				state.launchWebApp(appModule, appPort, proxyPort)
			}
		}
	}

	** Check if pods have been modified.
	Bool checkPods() {
		withState |state->Bool| {
			modified := state.podsModified 
			if (modified) {
				state.killWebApp(appModule)
				state.launchWebApp(appModule, appPort, proxyPort)
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
		// BugFix: Pod.list throws an Err is any pod is invalid (wrong dependencies etc) 
		// this way we don't even load the pod into memory!
		Env.cur().findAllPodNames.each |podName| {
			podTimeStamps[podName] = podFile(podName).modified
		}
		
		log.info(BsLogMsgs.appRestarterCachedPodTimestamps(podTimeStamps.size))
	}
	
	Bool podsModified()	{
		true == Env.cur().findAllPodNames.eachWhile |podName| {
			if (podFile(podName).modified > podTimeStamps[podName]) {
				log.info(BsLogMsgs.appRestarterPodUpdatd(podName, podTimeStamps[podName] - podFile(podName).modified))
				return true
			}
			return null
		}
	}
	
	Void launchWebApp(Str appModule, Int appPort, Int proxyPort) {
		log.info(BsLogMsgs.appRestarterLauchingApp(appModule, appPort))
		home := Env.cur.homeDir.osPath
		args := "java -cp ${home}/lib/java/sys.jar -Dfan.home=$home fanx.tools.Fan afBedSheet -pingProxy -pingProxyPort $proxyPort $appModule $appPort"
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
		Env? env := Env.cur
		file := env.workDir + `_doesnotexist_`

		// walk envs looking for pod file
		while (!file.exists && env != null) {
			if (env is PathEnv) {
				((PathEnv)env).path.eachWhile |p| {
					file = p + `lib/fan/${podName}.pod`
					return file.exists ? true : null
				}
			} else {
				file = env.workDir + `lib/fan/${podName}.pod`
			}
			env = env.parent
		}

		// verify exists and return
		if (!file.exists)
			throw Err("Pod file not found $podName")
		return file
	}	
}
