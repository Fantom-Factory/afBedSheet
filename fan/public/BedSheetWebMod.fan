using concurrent::Actor
using concurrent::ActorPool
using concurrent::AtomicRef
using concurrent::AtomicBool
using web::WebMod
using web::WebReq
using web::WebRes
using afIoc::IocErr
using afIoc::IocShutdownErr
using afIoc::Registry
using afIoc::RegistryBuilder
using afIocEnv::IocEnv
using afIocConfig::ConfigSource

** The `web::WebMod` to be passed to [Wisp]`http://fantom.org/doc/wisp/index.html`. 
const class BedSheetWebMod : WebMod {
	private const static Log log := Utils.getLog(BedSheetWebMod#)

	** The module name passed into the ctor.
	** Can be either a qualified type name of an AppModule or a pod name.
	const Str 			moduleName
	
	** The port number this Bed App will be listening on. 
	const Int 			port

	@NoDoc	// advanced usage
	const [Str:Obj?] 	registryOptions
	
	** When HTTP requests are received when BedSheet is starting up, then this message is returned to the client with a 500 status code.
	** 
	** Defaults to: 'The website is starting up... Please retry in a few seconds.'
	const Str			startupMessage	:= "The website is starting up... Please retry in a few seconds."
	
	private const AtomicBool	started			:= AtomicBool(false)
	private const AtomicRef		startupErrRef	:= AtomicRef()
	private const AtomicRef		registryRef		:= AtomicRef()
	private const AtomicRef		pipelineRef		:= AtomicRef()
	private const AtomicRef		errPrinterRef	:= AtomicRef()
	private const IocEnv		iocEnv			:= Type.find("afIocEnv::IocEnvImpl").make	// we can't use the registry, because we're waiting for it to startup!
	
	** The 'afIoc' registry. Can be 'null' if BedSheet has not started.
	Registry? registry {
		get { registryRef.val }
		private set { registryRef.val = it }
	}

	** The Err (if any) that occurred on service startup
	Err? startupErr {
		get { startupErrRef.val }
		private set { startupErrRef.val = it }
	}

	** Creates this 'WebMod'.
	** 'moduleName' can be a qualified type name of an AppModule or a pod name.
	** 'port' is required for reporting purposes only. (Wisp binds to the port, not BedSheet.)
	new make(Str moduleName, Int port, [Str:Obj?]? registryOptions := null, |This|? f := null) {
		this.moduleName 		= moduleName
		this.port 				= port
		this.registryOptions	= registryOptions ?: Utils.makeMap(Str#, Obj?#)
		f?.call(this)
	}

	@NoDoc
	override Void onService() {
		req.mod = this
		
		// Hey! Why you call us when we're not running, eh!??
		if (!started.val)
			return

		if (queueRequestsOnStartup)
			while (registry == null && startupErr == null) {
				// 200ms should be un-noticable to humans but a lifetime to a computer!
				Actor.sleep(200ms)
			}
		
		// web reqs still come in while we're processing onStart() so dispatch them quickly
		// We used to sleep / queue them up until ready but then, when processing 100s at once, 
		// it was easy to run into race conditions when lazily creating services.
		if (registry == null && startupErr == null) {
			res := (WebRes) Actor.locals["web.res"]
			res.sendErr(500, startupMessage)
			return
		}
		
		// rethrow the startup err if one occurred and let Wisp handle it
		if (startupErr != null)
			throw startupErr
		
		try {
			middlewarePipeline.service
			
		} catch (IocShutdownErr err) {
			// nothing we can do here
			return

		} catch (Err err) {
			// theoretically, this should have already been dealt with by our ErrMiddleware...
			// ...but it's handy for BedSheet development!
			if (registry != null) {	// reqs may come in before we've start up
				try {
					errPrinter := (ErrPrinterStr) registry.serviceById(ErrPrinterStr#.qname)
					Env.cur.err.printLine(errPrinter.errToStr(err))
				} catch
					err.trace(Env.cur.err)
			}
			throw err
		}
	}

	@NoDoc
	override Void onStart() {
		started.val = true
		try {
			log.info(BsLogMsgs.bedSheetWebMod_starting(moduleName, port))

			bob	:= createBob(moduleName, port, registryOptions)
			
			// Go!!!
			registry = bob.build.startup
	
			// start the destroyer!
			if (registryOptions["afBedSheet.pingProxy"] == true) {
				pingPort := (Int) registryOptions["afBedSheet.pingProxyPort"]
				destroyer := (AppDestroyer) registry.autobuild(AppDestroyer#, [ActorPool(), pingPort])
				destroyer.start
			}
			
			// print BedSheet connection details
			configSrc := (ConfigSource) registry.dependencyByType(ConfigSource#)
			host := (Uri) configSrc.get(BedSheetConfigIds.host, Uri#)			
			log.info(BsLogMsgs.bedSheetWebMod_started(bob["afBedSheet.appName"], host))

			// BUGFIX: eager load the middleware pipeline, so we can use the ErrMiddleware
			// otherwise Errs thrown when instantiating middleware end up in limbo
			// Errs from the FileHandler ctor are a prime example
			pipelineRef.val = registry.serviceById(MiddlewarePipeline#.qname)
			
		} catch (Err err) {
			startupErr = err
			throw err
		}
	}
	
	@NoDoc
	override Void onStop() {
		registry?.shutdown
		log.info(BsLogMsgs.bedSheetWebMod_stopping(moduleName))
	}

	** Should HTTP requests be queued while BedSheet is starting up? 
	** It is handy in dev, because it prevents you from constantly refreshing your browser!
	** But under heavy load in prod, the requests can quickly build up to 100s; so not such a good idea.
	** 
	** Returns 'false' in prod, 'true' otherwise. 
	virtual Bool queueRequestsOnStartup() {
		!iocEnv.isProd
	}

	** Returns a fully loaded IoC 'RegistryBuilder' that creates everything this Bed App needs. 
	static RegistryBuilder createBob(Str moduleName, Int port, [Str:Obj?]? options := null) {
		options = options ?: Utils.makeMap(Str#, Obj?#)
		
		Pod?  pod
		Type? mod
		
		// Pod name given...
		// lots of start up checks looking for pods and modules... 
		// see https://bitbucket.org/SlimerDude/afbedsheet/issue/1/add-a-warning-when-no-appmodule-is-passed
		if (!moduleName.contains("::")) {
			pod = Pod.find(moduleName, true)
			log.info(BsLogMsgs.bedSheetWebMod_foundPod(pod))
			mod = findModFromPod(pod)
		}

		// AppModule name given...
		if (moduleName.contains("::")) {
			mod = Type.find(moduleName, true)
			log.info(BsLogMsgs.bedSheetWebMod_foundType(mod))
			pod = mod.pod
		}

		// we're screwed! No module = no web app!
		if (mod == null)
			log.warn(BsLogMsgs.bedSheetWebMod_noModuleFound)
		
		// construct after the above messages so logs look nicer ("...adding module IocModule")
		bob := RegistryBuilder()

		// this defaults to false if not explicitly set to TRUE - trust me!
		transDeps := !(options["afBedSheet.noTransDeps"] == true)
		if (pod != null) {
			if (transDeps)
				bob.addModulesFromPod(pod.name, true)
			else
				log.info("Suppressing transitive dependencies...")
		}
		if (mod != null) {
			if (!bob.moduleTypes.contains(mod))
				bob.addModule(mod)
		}

		// A simple thing - ensure the BedSheet module is added! 
		// (transitive dependencies are added explicitly via @SubModule)
		if (!bob.moduleTypes.contains(BedSheetModule#))
			 bob.addModule(BedSheetModule#)

		// add extra modules - useful for testing
		if (options.containsKey("afBedSheet.iocModules"))
			bob.addModules(options["afBedSheet.iocModules"])

		dPort	:= (options.containsKey("afBedSheet.pingProxy") ? options["afBedSheet.pingProxyPort"] : null) ?: port
		regOpts := options.rw
		regOpts["afIoc.bannerText"] 	= easterEgg("Alien-Factory BedSheet v${BedSheetWebMod#.pod.version}, IoC v${Registry#.pod.version}")
		regOpts["afBedSheet.appPod"]	= pod
		regOpts["afBedSheet.appModule"]	= mod
		regOpts["afBedSheet.port"]		= dPort
		regOpts["afBedSheet.appName"]	= pod?.meta?.get("proj.name") ?: "Unknown"

		bob.options.addAll(regOpts)
		
		// startup afIoc
		return bob	
	}
	
	** Looks for an 'AppModule' in the given pod. 
	private static Type? findModFromPod(Pod pod) {
		mod := null
		modName := pod.meta["afIoc.module"]
		if (modName != null) {
			mod = Type.find(modName, true)
			log.info(BsLogMsgs.bedSheetWebMod_foundType(mod))
		} else {
			// we have a pod with no module meta... so lets guess the name 'AppModule'
			mod = pod.type("AppModule", false)
			if (mod != null) {
				log.info(BsLogMsgs.bedSheetWebMod_foundType(mod))
				log.warn(BsLogMsgs.bedSheetWebMod_addModuleToPodMeta(pod, mod))
			}
		}
		return mod
	}

	private static Str easterEgg(Str title) {
		quotes := loadQuotes
		if (quotes.isEmpty || (Int.random(0..8) != 2))
			return title
		return quotes[Int.random(0..<quotes.size)]
	}
	
	private MiddlewarePipeline middlewarePipeline() {
		pipelineRef.val
	}
	
	private static Str[] loadQuotes() {
		BedSheetWebMod#.pod.file(`/res/misc/quotes.txt`).readAllLines.exclude { it.isEmpty || it.startsWith("#")}
	}
}
