using concurrent::ActorPool
using concurrent::AtomicRef
using web::WebMod
using afIoc::Registry
using afIoc::RegistryBuilder

** The top-level `web::WebMod` to be passed to [Wisp]`http://fantom.org/doc/wisp/index.html`. 
const class BedSheetWebMod : WebMod {
	private const static Log log := Utils.getLog(BedSheetWebMod#)

	const Str 			moduleName
	const Int 			port
	const [Str:Obj] 	bedSheetOptions
	const [Str:Obj]? 	registryOptions
	
	private const AtomicRef	reg	:= AtomicRef()
	
	** The 'afIoc' registry
	Registry registry {
		get { reg.val }
		private set { }
	}

	new make(Str moduleName, Int port, [Str:Obj] bedSheetOptions, [Str:Obj]? registryOptions := null) {
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

		Pod? pod
		Type? mod
		
		// pod name given...
		// lots of start up checks looking for pods and modules... 
		// see https://bitbucket.org/SlimerDude/afbedsheet/issue/1/add-a-warning-when-no-appmodule-is-passed
		if (!moduleName.contains("::")) {
			pod = Pod.find(moduleName, true)
			if (pod != null) {
				log.info(BsLogMsgs.bedSheetWebModFoundPod(pod))
				modName := pod.meta["afIoc.module"]
				if (modName != null) {
					mod = Type.find(modName, false)
					log.info(BsLogMsgs.bedSheetWebModFoundType(mod))
					// reset back to null - so we add the whole module with trans deps
					mod = null
				} else {
					// we have a pod name with no module meta... guess a type of AppModule
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
		}

		// mod name given...
		if (moduleName.contains("::")) {
			mod = Type.find(moduleName, true)
			log.info(BsLogMsgs.bedSheetWebModFoundType(mod))
		}

		// construct this last so logs look nicer ("...adding module IocModule")
		bob := RegistryBuilder()
		if (pod != null) {
			bob.addModulesFromDependencies(pod, true)
		}
		if (mod != null) {
			bob.addModule(mod)			
		}

		// A simple thing - ensure the BedSheet module is added!
		if (!bob.moduleTypes.contains(BedSheetModule#))
			// wrap in an 'if' to avoid dup warnings
			bob.addModule(BedSheetModule#)
		
		bannerText	:= easterEgg("Alien-Factory BedSheet v${typeof.pod.version}, IoC v${Registry#.pod.version}")
		options 	:= Str:Obj["bannerText":bannerText]
		if (registryOptions != null)
			options.setAll(registryOptions)

		if (bedSheetOptions.containsKey("iocModules"))
			bob.addModules(bedSheetOptions["iocModules"])

		reg.val = bob.build(options).startup

		if (bedSheetOptions["pingProxy"] == true) {
			pingPort := (Int) bedSheetOptions["pingProxyPort"]
			destroyer := (AppDestroyer) registry.autobuild(AppDestroyer#, [ActorPool(), pingPort])
			destroyer.start
		}
	}

	override Void onStop() {
		reg := (Registry?) reg.val
		reg?.shutdown
		log.info(BsLogMsgs.bedSheetWebModStopping(moduleName))
	}
	
	private Str easterEgg(Str title) {
		quotes := loadQuotes
		if (quotes.isEmpty || (Int.random(0..8) != 2))
			return title
		return quotes[Int.random(0..<quotes.size)]
	}
	
	private Str[] loadQuotes() {
		["hhh"]
//		typeof.pod.file(`/res/misc/quotes.txt`).readAllLines.exclude { it.isEmpty || it.startsWith("#")}
	}
}
