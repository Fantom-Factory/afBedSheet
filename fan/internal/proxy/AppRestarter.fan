using afIoc::ConcurrentState
using concurrent::Actor
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
	Void checkPods() {
		withState |state| {
			if (state.podsModified) {
				state.killWebApp(appModule)
				state.launchWebApp(appModule, appPort, proxyPort)
				Actor.sleep(2sec)
				state.updateTimeStamps
			}
		}
		// TODO: afIoc 1.3.2 update afIoc and change to
//		getFuture { ... }.get(30sec)
	}
	
	private Void withState(|AppRestarterState| state) {
		conState.withState(state)
	}
}

internal class AppRestarterState {
	private const static Log log := Utils.getLog(AppRestarter#)
	
	Pod:DateTime?	podTimeStamps	:= [:]
	Process?		realWebApp

	Void updateTimeStamps() {
		Pod.list.each |pod| { podTimeStamps[pod] = podFile(pod).modified }
		log.info(BsLogMsgs.appRestarterCachedPodTimestamps(podTimeStamps.size))
	}
	
	Bool podsModified()	{
		true == Pod.list.eachWhile |pod| {
			if (podFile(pod).modified > podTimeStamps[pod]) {
				log.info(BsLogMsgs.appRestarterPodUpdatd(pod, podTimeStamps[pod] - podFile(pod).modified))
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
	
	private File podFile(Pod pod) {
		Env? env := Env.cur
		file := env.workDir + `_doesnotexist_`

		// walk envs looking for pod file
		while (!file.exists && env != null) {
			if (env is PathEnv) {
				((PathEnv)env).path.eachWhile |p| {
					file = p + `lib/fan/${pod.name}.pod`
					return file.exists ? true : null
				}
			} else {
				file = env.workDir + `lib/fan/${pod.name}.pod`
			}
			env = env.parent
		}

		// verify exists and return
		if (!file.exists)
			throw Err("Pod file not found $pod.name")
		return file
	}	
}
