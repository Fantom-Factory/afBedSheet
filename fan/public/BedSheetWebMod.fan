using concurrent::ActorPool
using concurrent::AtomicRef
using web::WebMod
using afIoc::Registry
using afIoc::RegistryBuilder
using afIocConfig::IocConfigModule

** The top-level `web::WebMod` to be passed to [Wisp]`http://fantom.org/doc/wisp/index.html`. 
const class BedSheetWebMod : WebMod {
	private const static Log log := Utils.getLog(BedSheetWebMod#)

	const Str 			moduleName
	const Int 			port
	const [Str:Obj?] 	bedSheetOpts
	const [Str:Obj?] 	registryOpts
	
	private const AtomicRef	atomicReg		:= AtomicRef()
	private const AtomicRef	atomicAppPod	:= AtomicRef()
	
	** The 'afIoc' registry. Maybe 'null' if BedSheet did not startup properly.
	Registry? registry {
		get { atomicReg.val }
		private set { atomicReg.val = it }
	}

	new make(Str moduleName, Int port, [Str:Obj?] bedSheetOptions, [Str:Obj?]? registryOptions := null) {
		this.moduleName 	= moduleName
		this.port 			= port
		this.registryOpts	= registryOptions ?: Utils.makeMap(Str#, Obj?#)
		this.bedSheetOpts	= bedSheetOptions
	}

	override Void onService() {
		req.mod = this
		try {
			httpPipeline := (HttpPipeline) registry.dependencyByType(HttpPipeline#)
			httpPipeline.service
		} catch (Err err) {
			// theoretically, this should have already been dealt with by our Err Pipeline Processor...
			// ...but it's handy for BedSheet development!
			errPrinter := (ErrPrinterStr) registry.dependencyByType(ErrPrinterStr#)
			Env.cur.err.printLine(errPrinter.errToStr(err))
			throw err
		}
	}

	override Void onStart() {
		log.info(BsLogMsgs.bedSheetWebModStarting(moduleName, port))

		Pod?  pod
		Type? mod
		
		// Pod name given...
		// lots of start up checks looking for pods and modules... 
		// see https://bitbucket.org/SlimerDude/afbedsheet/issue/1/add-a-warning-when-no-appmodule-is-passed
		if (!moduleName.contains("::")) {
			pod = Pod.find(moduleName, true)
			log.info(BsLogMsgs.bedSheetWebModFoundPod(pod))
			modName := pod.meta["afIoc.module"]
			if (modName != null) {
				mod = Type.find(modName, false)
				log.info(BsLogMsgs.bedSheetWebModFoundType(mod))
			} else {
				// we have a pod with no module meta... so lets guess the name 'AppModule'
				mod = pod.type("AppModule", false)
				if (mod != null) {
					log.info(BsLogMsgs.bedSheetWebModFoundType(mod))
					log.warn(BsLogMsgs.bedSheetWebModAddModuleToPodMeta(pod, mod))
				}
			}				
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

		// this defaults to true if not explicitly FALSE - trust me!
		transDeps := !(bedSheetOpts["noTransDeps"] == false)
		if (pod != null) {
			if (transDeps)
				bob.addModulesFromDependencies(pod, true)
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
		if (bedSheetOpts.containsKey("iocModules"))
			bob.addModules(bedSheetOpts["iocModules"])

		registryOpts := this.registryOpts.rw
		registryOpts["bannerText"] 			= easterEgg("Alien-Factory BedSheet v${typeof.pod.version}, IoC v${Registry#.pod.version}")
		registryOpts["bedSheetMetaData"]	= BedSheetMetaDataImpl(pod, mod, bedSheetOpts)

		// startup afIoc
		registry = bob.build(registryOpts).startup

		// start the destroyer!
		if (bedSheetOpts["pingProxy"] == true) {
			pingPort := (Int) bedSheetOpts["pingProxyPort"]
			destroyer := (AppDestroyer) registry.autobuild(AppDestroyer#, [ActorPool(), pingPort])
			destroyer.start
		}
	}

	override Void onStop() {
		registry?.shutdown
		log.info(BsLogMsgs.bedSheetWebModStopping(moduleName))
	}
	
	private Str easterEgg(Str title) {
		quotes := loadQuotes
		if (quotes.isEmpty || (Int.random(0..8) != 2))
			return title
		return quotes[Int.random(0..<quotes.size)]
	}
	
	private Str[] loadQuotes() {
		typeof.pod.file(`/res/misc/quotes.txt`).readAllLines.exclude { it.isEmpty || it.startsWith("#")}
	}
}
