using concurrent::Actor
using concurrent::ActorPool
using concurrent::AtomicRef
using concurrent::AtomicBool
using web::WebMod
using afIoc::IocErr
using afIoc::Registry
using afIoc::RegistryBuilder
using afIocConfig::IocConfigSource

** The `web::WebMod` to be passed to [Wisp]`http://fantom.org/doc/wisp/index.html`. 
const class BedSheetWebMod : WebMod {
	private const static Log log := Utils.getLog(BedSheetWebMod#)

	** The module name passed into the ctor.
	** Can be either a qualified type name of an AppModule or a pod name.
	const Str 			moduleName
	
	** The port number this Bed App will be listening on. 
	const Int 			port

	@NoDoc	// advanced usage
	const [Str:Obj?] 	bedSheetOptions
	@NoDoc	// advanced usage
	const [Str:Obj?] 	registryOptions
	
	private const AtomicBool	started			:= AtomicBool(false)
	private const AtomicRef		startupErrA		:= AtomicRef()
	private const AtomicRef		registryRef		:= AtomicRef()
	private const AtomicRef		pipelineRef		:= AtomicRef()
	private const AtomicRef		errPrinterRef	:= AtomicRef()
	
	** The 'afIoc' registry. Can be 'null' if BedSheet has not started.
	Registry? registry {
		get { registryRef.val }
		private set { registryRef.val = it }
	}

	** The Err (if any) that occurred on service startup
	Err? startupErr {
		get { startupErrA.val }
		private set { startupErrA.val = it }
	}

	** Creates this 'WebMod'.
	** 'moduleName' can be a qualified type name of an AppModule or a pod name.
	new make(Str moduleName, Int port, [Str:Obj?]? bedSheetOptions := null, [Str:Obj?]? registryOptions := null) {
		this.moduleName 		= moduleName
		this.port 				= port
		this.bedSheetOptions	= bedSheetOptions ?: Utils.makeMap(Str#, Obj?#)
		this.registryOptions	= registryOptions ?: Utils.makeMap(Str#, Obj?#)
	}

	@NoDoc
	override Void onService() {
		req.mod = this
		
		// Hey! Why you call us when we're not running, eh!??
		if (!started.val)
			return
		
		// web reqs can come while we're still processing onStart() so lets wait for either  
		// condition to occur (good or bad) - as some reg startup times may be seconds long
		while (registry == null && startupErr == null) {
			// 200ms should be un-noticable to humans but a lifetime to a computer!
			Actor.sleep(200ms)
		}
		
		// rethrow the startup err if one occurred and let Wisp handle it
		if (startupErr != null)
			throw startupErr
		
		try {
			middlewarePipeline.service
			
		} catch (Err err) {
			// nothing we can do here
			if (err is IocErr && err.msg.contains("Method may no longer be invoked - Registry has already been shutdown"))
				return
			
			// theoretically, this should have already been dealt with by our ErrMiddleware...
			// ...but it's handy for BedSheet development!
			if (registry != null) {	// reqs may come in before we've start up
				try {
					errPrinter := (ErrPrinterStr) registry.serviceById(ErrPrinterStr#.qname)
					Env.cur.err.printLine(errPrinter.errToStr(err))
				} catch {
					err.trace(Env.cur.err)
				}
			}
			throw err
		}
	}

	@NoDoc
	override Void onStart() {
		started.val = true
		try {
			log.info(BsLogMsgs.bedSheetWebModStarting(moduleName, port))

			bob		:= createBob(moduleName, port, bedSheetOptions, registryOptions)
			bsMeta	:= (BedSheetMetaData) bob.options["afBedSheet.metaData"] 
			
			// Go!!!
			registry = bob.build.startup
	
			// start the destroyer!
			if (bedSheetOptions["pingProxy"] == true) {
				pingPort := (Int) bedSheetOptions["pingProxyPort"]
				destroyer := (AppDestroyer) registry.autobuild(AppDestroyer#, [ActorPool(), pingPort])
				destroyer.start
			}
			
			// print BedSheet connection details
			configSrc := (IocConfigSource) registry.dependencyByType(IocConfigSource#)
			host := (Uri) configSrc.get(BedSheetConfigIds.host, Uri#)			
			log.info(BsLogMsgs.bedSheetWebModStarted(bsMeta.appName, host))

		} catch (Err err) {
			startupErr = err
			throw err
		}
	}
	
	@NoDoc
	override Void onStop() {
		registry?.shutdown
		log.info(BsLogMsgs.bedSheetWebModStopping(moduleName))
	}

	** Returns a fully loaded IoC 'RegistryBuilder' that creates everything this Bed App needs. 
	static RegistryBuilder createBob(Str moduleName, Int port, [Str:Obj?]? bedSheetOptions := null, [Str:Obj?]? registryOptions := null) {
		bedSheetOptions = bedSheetOptions ?: Utils.makeMap(Str#, Obj?#)
		registryOptions = registryOptions ?: Utils.makeMap(Str#, Obj?#)
		
		Pod?  pod
		Type? mod
		
		// Pod name given...
		// lots of start up checks looking for pods and modules... 
		// see https://bitbucket.org/SlimerDude/afbedsheet/issue/1/add-a-warning-when-no-appmodule-is-passed
		if (!moduleName.contains("::")) {
			pod = Pod.find(moduleName, true)
			log.info(BsLogMsgs.bedSheetWebModFoundPod(pod))
			mod = findModFromPod(pod)
		}

		// AppModule name given...
		if (moduleName.contains("::")) {
			mod = Type.find(moduleName, true)
			log.info(BsLogMsgs.bedSheetWebModFoundType(mod))
			pod = mod.pod
		}

		// we're screwed! No module = no web app!
		if (mod == null)
			log.warn(BsLogMsgs.bedSheetWebModNoModuleFound)
		
		// construct after the above messages so logs look nicer ("...adding module IocModule")
		bob := RegistryBuilder()

		// this defaults to false if not explicitly set to TRUE - trust me!
		transDeps := !(bedSheetOptions["noTransDeps"] == true)
		if (pod != null) {
			if (transDeps)
				bob.addModulesFromPod(pod, true)
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
		if (bedSheetOptions.containsKey("iocModules"))
			bob.addModules(bedSheetOptions["iocModules"])

		dPort 		 := (bedSheetOptions.containsKey("pingProxy") ? bedSheetOptions["pingProxyPort"] : null) ?: port
		bsMeta		 := BedSheetMetaDataImpl(pod, mod, dPort, bedSheetOptions)
		registryOpts := registryOptions.rw
		registryOpts["afIoc.bannerText"] 	= easterEgg("Alien-Factory BedSheet v${BedSheetWebMod#.pod.version}, IoC v${Registry#.pod.version}")
		registryOpts["afBedSheet.metaData"]	= bsMeta

		bob.options.addAll(registryOpts)
		
		// startup afIoc
		return bob	
	}
	
	** Looks for an 'AppModule' in the given pod. 
	private static Type? findModFromPod(Pod pod) {
		mod := null
		modName := pod.meta["afIoc.module"]
		if (modName != null) {
			mod = Type.find(modName, true)
			log.info(BsLogMsgs.bedSheetWebModFoundType(mod))
		} else {
			// we have a pod with no module meta... so lets guess the name 'AppModule'
			mod = pod.type("AppModule", false)
			if (mod != null) {
				log.info(BsLogMsgs.bedSheetWebModFoundType(mod))
				log.warn(BsLogMsgs.bedSheetWebModAddModuleToPodMeta(pod, mod))
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
	
	// lazy load the MiddlewarePipeline
	private MiddlewarePipeline middlewarePipeline() {
		pipe := pipelineRef.val
		if (pipe == null)
			pipe = pipelineRef.val = registry.serviceById(MiddlewarePipeline#.qname)
		return pipe
	}
	
	private static Str[] loadQuotes() {
		BedSheetWebMod#.pod.file(`/res/misc/quotes.txt`).readAllLines.exclude { it.isEmpty || it.startsWith("#")}
	}
}
