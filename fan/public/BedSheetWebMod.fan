using concurrent::AtomicRef
using web
using afIoc

const class BedSheetWebMod : WebMod {
	private const static Log log := Utils.getLog(BedSheetWebMod#)

	const Str 			moduleName
	const [Str:Obj]? 	registryOptions
	
	private const AtomicRef	registry	:= AtomicRef()
	
	Registry reg {
		get { registry.val }
		set { }
	}
	
	new make(Str moduleName, [Str:Obj]? registryOptions := null) {
		this.moduleName 		= moduleName
		this.registryOptions	= registryOptions
	}
	
	override Void onService() {
		req.mod = this
		((BedSheetService) reg.dependencyByType(BedSheetService#)).service
		res.done
	}
	
	override Void onStart() {
		bob := RegistryBuilder()

		// pod name given...
		if (!moduleName.contains("::")) {
			pod := Pod.find(moduleName, true)
			bob.addModulesFromDependencies(pod, true)			
		}

		// mod name given...
		if (moduleName.contains("::")) {
			mod := Type.find(moduleName, true)
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
		reg.dependencyByType(Router#)
	}

	override Void onStop() {
		reg := (Registry?) registry.val
		reg?.shutdown
		log.info("\"Goodbye!\" from afBedSheet!")
	}
}
