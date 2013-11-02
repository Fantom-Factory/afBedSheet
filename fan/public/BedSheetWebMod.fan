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
	const [Str:Obj?] 	bedSheetOptions
	const [Str:Obj?]? 	registryOptions
	
	private const AtomicRef	atomicReg		:= AtomicRef()
	private const AtomicRef	atomicAppPod	:= AtomicRef()
	
	** The 'afIoc' registry. Maybe 'null' if BedSheet did not startup properly.
	Registry? registry {
		get { atomicReg.val }
		private set { atomicReg.val = it }
	}

	new make(Str moduleName, Int port, [Str:Obj?] bedSheetOptions, [Str:Obj?]? registryOptions := null) {
		this.moduleName 		= moduleName
		this.port 				= port
		this.registryOptions	= registryOptions
		this.bedSheetOptions	= bedSheetOptions
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
		Pod?  appPod
		Type? appMod
		
		// pod name given...
		// lots of start up checks looking for pods and modules... 
		// see https://bitbucket.org/SlimerDude/afbedsheet/issue/1/add-a-warning-when-no-appmodule-is-passed
		if (!moduleName.contains("::")) {
			pod = Pod.find(moduleName, true)
			log.info(BsLogMsgs.bedSheetWebModFoundPod(pod))
			modName := pod.meta["afIoc.module"]
			if (modName != null) {
				mod = Type.find(modName, false)
				log.info(BsLogMsgs.bedSheetWebModFoundType(mod))
				// reset back to null - so we add the whole module with trans deps
				appMod = mod
				mod = null
			} else {
				// we have a pod with no module meta... guess a type of AppModule
				mod = pod.type("AppModule", false)
				if (mod != null) {
					log.info(BsLogMsgs.bedSheetWebModFoundType(mod))
					log.warn(BsLogMsgs.bedSheetWebModAddModuleToPodMeta(pod, mod))
				} else {
					// we're screwed! No module = no web app!
					log.warn(BsLogMsgs.bedSheetWebModNoModuleFound)
				}
			}				
		}

		// mod name given...
		if (moduleName.contains("::")) {
			mod = Type.find(moduleName, true)
			log.info(BsLogMsgs.bedSheetWebModFoundType(mod))
		}

		// construct after the above messages so logs look nicer ("...adding module IocModule")
		bob := RegistryBuilder()
		
		transDeps := !bedSheetOptions.containsKey("noTransDeps")
		if (!transDeps)
			log.info("Suppressing transitive dependencies...")
		if (pod != null) {
			bob.addModulesFromDependencies(pod, transDeps)
		}
		if (mod != null) {
			bob.addModulesFromDependencies(mod.pod, transDeps)
			if (!bob.moduleTypes.contains(mod))
				bob.addModule(mod)
		}

		// A simple thing - ensure the BedSheet module is added! 
		// (Ensure trans deps are added explicitly via @SubModule)
		if (!bob.moduleTypes.contains(BedSheetModule#))
			 bob.addModule(BedSheetModule#)

		bannerText	:= easterEgg("Alien-Factory BedSheet v${typeof.pod.version}, IoC v${Registry#.pod.version}")
		options 	:= Str:Obj?["bannerText":bannerText]
		if (registryOptions != null)
			options.setAll(registryOptions)

		if (bedSheetOptions.containsKey("iocModules"))
			bob.addModules(bedSheetOptions["iocModules"])

		
		// create meta data
		appMod = (appMod != null) ? appMod : mod
		appPod = (pod    != null) ?    pod : appMod?.pod
		meta  := BedSheetMetaDataImpl(appPod, appMod, bedSheetOptions)
		options["bedSheetMetaData"] = meta
		
		// startup afIoc
		registry = bob.build(options).startup

		// start the destroyer!
		if (bedSheetOptions["pingProxy"] == true) {
			pingPort := (Int) bedSheetOptions["pingProxyPort"]
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
