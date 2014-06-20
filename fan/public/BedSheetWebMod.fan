using concurrent::Actor
using concurrent::ActorPool
using concurrent::AtomicRef
using concurrent::AtomicBool
using web::WebMod
using afIoc::Registry
using afIoc::RegistryBuilder
using afIocConfig::IocConfigSource

** The top-level `web::WebMod` to be passed to [Wisp]`http://fantom.org/doc/wisp/index.html`. 
const class BedSheetWebMod : WebMod {
	private const static Log log := Utils.getLog(BedSheetWebMod#)

	const Str 			moduleName
	const Int 			port
	const [Str:Obj?] 	bedSheetOptions
	const [Str:Obj?] 	registryOptions
	
	private const AtomicBool	started		:= AtomicBool(false)
	private const AtomicRef		startupErrA	:= AtomicRef()
	private const AtomicRef		atomicReg	:= AtomicRef()
	private const AtomicRef		atomicPipe	:= AtomicRef()
	
	** The 'afIoc' registry. Can be 'null' if BedSheet has not started.
	Registry? registry {
		get { atomicReg.val }
		private set { atomicReg.val = it }
	}

	** An Err (if any) that occured on service startup
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
			// theoretically, this should have already been dealt with by our ErrMiddleware...
			// ...but it's handy for BedSheet development!
			if (registry != null) {	// reqs may come in before we've start up
				errPrinter := (ErrPrinterStr) registry.dependencyByType(ErrPrinterStr#)
				Env.cur.err.printLine(errPrinter.errToStr(err))
			}
			throw err
		}
	}

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
			
			configSrc := (IocConfigSource) registry.dependencyByType(IocConfigSource#)
			host := (Uri?) configSrc.get(BedSheetConfigIds.host, Uri#)
			verifyAndLogHost(bsMeta.appName, host)

		} catch (Err err) {
			startupErr = err
			throw err
		}
	}
	
	override Void onStop() {
		registry?.shutdown
		log.info(BsLogMsgs.bedSheetWebModStopping(moduleName))
	}

	** Returns a fully loaded 'RegistryBuilder' ready to build an IoC. 
	static RegistryBuilder createBob(Str moduleName, Int port, [Str:Obj?] bedSheetOptions := [:], [Str:Obj?] registryOptions := [:]) {
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

	static internal Void verifyAndLogHost(Str appName, Uri host) {
		// assert host in correct format
		if (host.scheme == null || host.auth == null)
			throw BedSheetErr(BsErrMsgs.startupHostMustHaveSchemeAndAuth(BedSheetConfigIds.host, host))
		if (!host.pathStr.isEmpty && host.pathStr != "/")
			throw BedSheetErr(BsErrMsgs.startupHostMustNotHavePath(BedSheetConfigIds.host, host))
		
		// print BedSheet connection details
		log.info(BsLogMsgs.bedSheetWebModStarted(appName, host))
	}
	
	private static Str easterEgg(Str title) {
		quotes := loadQuotes
		if (quotes.isEmpty || (Int.random(0..8) != 2))
			return title
		return quotes[Int.random(0..<quotes.size)]
	}
	
	// lazy load the MiddlewarePipeline
	private MiddlewarePipeline middlewarePipeline() {
		pipe := atomicPipe.val
		if (pipe != null)
			return pipe
		atomicPipe.val = registry.dependencyByType(MiddlewarePipeline#)
		return atomicPipe.val
	}
	
	private static Str[] loadQuotes() {
		BedSheetWebMod#.pod.file(`/res/misc/quotes.txt`).readAllLines.exclude { it.isEmpty || it.startsWith("#")}
	}
}
