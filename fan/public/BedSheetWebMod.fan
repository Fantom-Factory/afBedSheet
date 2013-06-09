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
	
	private const AtomicRef	registry	:= AtomicRef()
	
	Registry reg {
		get { registry.val }
		set { }
	}
	
	new make(Str moduleName, Int port, [Str:Obj] bedSheetOptions, [Str:Obj]? registryOptions := null) {
		this.moduleName 		= moduleName
		this.port 				= port
		this.registryOptions	= registryOptions
		this.bedSheetOptions	= bedSheetOptions
	}

	override Void onService() {
		req.mod = this
		((BedSheetService) reg.dependencyByType(BedSheetService#)).service
		res.done
	}

	override Void onStart() {
		log.info(BsLogMsgs.bedSheetWebModStarting(moduleName, port))

		// pod name given...
		Pod? pod
		if (!moduleName.contains("::")) {
			pod = Pod.find(moduleName, true)
			log.info(BsLogMsgs.bedSheetWebModFoundPod(pod))
		}

		// mod name given...
		Type? mod
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
			bob.addModule(BedSheetModule#)
			bob.addModule(mod)			
		}
		
		// TODO: Easter Egg please!
		bannerText	:= "Alien-Factory BedSheet v${typeof.pod.version}, IoC v${Registry#.pod.version}"
		options 	:= Str:Obj["bannerText":bannerText]
		if (registryOptions != null)
			options.setAll(registryOptions)

		registry.val = bob.build(options).startup

		// validate routes on startup
		reg.dependencyByType(RouteSource#)

		if (bedSheetOptions["pingProxy"] == true) {
			pingPort := (Int) bedSheetOptions["pingProxyPort"]
			destroyer := reg.autobuild(AppDestroyer#, [ActorPool(), pingPort]) as AppDestroyer
			destroyer.start
		}
	}

	override Void onStop() {
		reg := (Registry?) registry.val
		reg?.shutdown
		log.info(BsLogMsgs.bedSheetWebModStopping(moduleName))
	}
}
