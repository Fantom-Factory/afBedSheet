using afConcurrent::SynchronizedState
using concurrent::ActorPool
using concurrent::Future
using util::PathEnv

internal const class AppRestarter {
	private const static Log 		log 		:= Utils.getLog(AppRestarter#)
	private const SynchronizedState	state
	
	const Str	appName
	const Int 	appPort
	const Str	appParams
	
	new make(BedSheetBuilder bob, Int appPort) {
		appPod := (Pod) bob.options[BsConstants.meta_appPod]
		if (appPod.meta["pod.isScript"] == "true")
			throw Err(BsLogMsgs.appRestarter_canNotProxyScripts(appPod.name))
		
		this.appName 	= bob.appName
		this.appPort 	= appPort
		this.appParams	= bob.toStringy
		// as we're not run inside afIoc, we don't have ActorPools
		this.state		= SynchronizedState(ActorPool(), AppRestarterState#)
	}

	Void startApp() {
		state->startWebApp(appName, appPort, appParams)
	}
	
	Void stopApp() {
		state->stopWebApp(appName)
	}

	Void restartApp() {
		state->restartWebApp(appName, appPort, appParams)
//		state.asyncLater(100ms) |s| {
//			s->restartWebApp(appName, appPort, appParams)
//		}
	}
}

internal class AppRestarterState {
	private const static Log log := Utils.log
	
	Process?	realWebApp
	Duration?	startedOn
	
	Void startWebApp(Str appName, Int appPort, Str appParams) {
		if (realWebApp != null) return

		log.info(BsLogMsgs.appRestarter_lauchingApp(appName, appPort))
		try {		
			realWebApp = fanProcess([MainProxied#.qname, appParams]) 
			log.info(BsLogMsgs.appRestarter_process(realWebApp.command.join(" ")))
			realWebApp.run

			startedOn = Duration.now
		} catch (Err err)
			throw BedSheetErr(BsErrMsgs.appRestarter_couldNotLaunch(appName), err)
	}

	Void stopWebApp(Str appName) {
		if (realWebApp == null) return

		log.info(BsLogMsgs.appRestarter_killingApp(appName))
		realWebApp.kill
		realWebApp = null
	}

	Void restartWebApp(Str appName, Int appPort, Str appParams) {
		if (startedOn == null || (Duration.now - startedOn) > 3sec) {
			stopWebApp(appName)
			startWebApp(appName, appPort, appParams)			
		} else {
			ago := Duration.now - startedOn
			log.info("${appName} only restarted ${ago.toLocale} ago - not restarting it again just yet!")
		}
	}

	static Process fanProcess(Str[] cmd) {
		homeDir		:= Env.cur.homeDir.normalize
		classpath	:= [homeDir + `lib/java/sys.jar`, homeDir + `lib/java/jline.jar`].join(File.pathSep) { it.osPath } 
		javaOpts	:= Env.cur.config(Pod.find("sys"), "java.options", "")
		args 		:= ["java", javaOpts, "-cp", classpath, "-Dfan.home=${homeDir.osPath}", "fanx.tools.Fan"].addAll(cmd)
		return Process(args)
	}
}
