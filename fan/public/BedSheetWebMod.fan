using concurrent::AtomicRef
using web
using afIoc

const class BedSheetWebMod : WebMod {

	const Str moduleName
	
	private const AtomicRef	registry	:= AtomicRef()
	
	Registry reg {
		get { registry.val }
		set { }
	}
	
	// pass registry startup optoins?
	new make(Str moduleName) {
		this.moduleName = moduleName
	}
	
	
	override Void onService() {
		req.mod = this
		
		((BedSheetService) reg.dependencyByType(BedSheetService#)).service
		
		res.done
	}
	
	override Void onStart() {
		// TODO: log BedSheet version

		bob := RegistryBuilder()

		// TODO: wrap up in try 
		pod := Pod.find(moduleName, false)
		mod := (pod == null) ? Type.find(moduleName, false) : null

		
		if (pod != null)
			bob.addModulesFromDependencies(pod, true)
		
		if (mod != null) {
			bob.addModule(BedSheetModule#)
			bob.addModule(mod)
		}
		
		registry.val = bob.build.startup
		
		// validate routes on startup
		reg.dependencyByType(Router#)
	}

	override Void onStop() {
		Env.cur.err.printLine("Goodbye!")	//TODO:log
		reg := (Registry?) registry.val
		reg?.shutdown
	}
}
