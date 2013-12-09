using concurrent::Actor
using concurrent::ActorPool
using concurrent::AtomicRef
using concurrent::AtomicBool
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
	const [Str:Obj?] 	registryOptions
	
	private const AtomicBool	started		:= AtomicBool(false)
	private const AtomicRef		startupErrA	:= AtomicRef()
	private const AtomicRef		atomicReg	:= AtomicRef()
	
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

	new make(Str moduleName, Int port, [Str:Obj?] bedSheetOptions, [Str:Obj?]? registryOptions := null) {
		this.moduleName 		= moduleName
		this.port 				= port
		this.registryOptions	= registryOptions ?: Utils.makeMap(Str#, Obj?#)
		this.bedSheetOptions	= bedSheetOptions
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
			httpPipeline := (HttpPipeline) registry.dependencyByType(HttpPipeline#)
			httpPipeline.service
			
		} catch (Err err) {
			// theoretically, this should have already been dealt with by our Err Pipeline Processor...
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
			if (bedSheetOptions.containsKey("iocModules"))
				bob.addModules(bedSheetOptions["iocModules"])
	
			registryOpts := this.registryOptions.rw
			registryOpts["bannerText"] 			= easterEgg("Alien-Factory BedSheet v${typeof.pod.version}, IoC v${Registry#.pod.version}")
			registryOpts["bedSheetMetaData"]	= BedSheetMetaDataImpl(pod, mod, bedSheetOptions)
	
			// startup afIoc
			registry = bob.build(registryOpts).startup
	
			// start the destroyer!
			if (bedSheetOptions["pingProxy"] == true) {
				pingPort := (Int) bedSheetOptions["pingProxyPort"]
				destroyer := (AppDestroyer) registry.autobuild(AppDestroyer#, [ActorPool(), pingPort])
				destroyer.start
			}
			
		} catch (Err err) {
			startupErr = err
			throw err
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
