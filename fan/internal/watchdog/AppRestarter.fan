using afConcurrent::SynchronizedState
using concurrent::ActorPool
using concurrent::Future
using util::PathEnv

internal const class AppRestarter {
	private const static Log 		log 		:= Utils.getLog(AppRestarter#)
	private const SynchronizedState	conState
	
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
		this.conState	= SynchronizedState(ActorPool(), AppRestarterState#)
	}

	Void startApp() {
		withState |state| {
			if (state.realWebApp == null)
				state.launchWebApp(appName, appPort, appParams)
		}
	}
	
	Void stopAdd() {
		withState |state| {
			state.killWebApp(appName)
		}.get(12sec)
	}

	Void restartApp() {
		withState |state->Obj?| {
			state.killWebApp(appName)
			state.launchWebApp(appName, appPort, appParams)
			return null
		}.get(30sec)
	}
	
	private Future withState(|AppRestarterState| state) {
		conState.async(state)
	}
}

internal class AppRestarterState {
	private const static Log log := Utils.log
	
	Process?		realWebApp
	
	Void launchWebApp(Str appName, Int appPort, Str appParams) {
		if (realWebApp != null) return

		log.info(BsLogMsgs.appRestarter_lauchingApp(appName, appPort))
		try {		
			realWebApp = fanProcess([MainProxied#.qname, appParams]) 
			log.info(BsLogMsgs.appRestarter_process(realWebApp.command.join(" ")))
			realWebApp.run
		} catch (Err err)
			throw BedSheetErr(BsErrMsgs.appRestarter_couldNotLaunch(appName), err)
	}

	Void killWebApp(Str appName) {
		if (realWebApp == null) return

		log.info(BsLogMsgs.appRestarter_killingApp(appName))
		realWebApp.kill
		realWebApp = null
	}

	static Process fanProcess(Str[] cmd) {
		homeDir		:= Env.cur.homeDir.normalize
		classpath	:= [homeDir + `lib/java/sys.jar`, homeDir + `lib/java/jline.jar`].join(File.pathSep) { it.osPath } 
		javaOpts	:= Env.cur.config(Pod.find("sys"), "java.options", "")
		args 		:= ["java", javaOpts, "-cp", classpath, "-Dfan.home=${homeDir.osPath}", "fanx.tools.Fan"].addAll(cmd)
		return Process(args)
	}
}
