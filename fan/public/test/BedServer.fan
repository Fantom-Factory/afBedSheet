using afIoc::Registry
using afIoc::RegistryBuilder
using wisp::MemWispSessionStore
using wisp::WispSessionStore

class BedServer {
	private Type[]			iocModules	:= [,]
	
	Registry? registry {
		private set
	}

	new make(Type? iocModule := null) {
		addModule(BedSheetModule#)
		if (iocModule != null)
			addModule(iocModule)
	}

	BedServer addModule(Type iocModule) {
		iocModules.add(iocModule)
		return this
	}

	BedServer startup() {
		bannerText	:= "Alien-Factory BedServer v${typeof.pod.version}, IoC v${Registry#.pod.version}"
		
		bob := RegistryBuilder()
		bob.addModules(iocModules)
		registry = bob.build(["bannerText":bannerText]).startup
		return this
	}

	BedServer shutdown() {
		registry.shutdown
		return this
	}
	
	BedClient makeClient() {
		BedClient(this)
	}

	// ---- Registry Methods ----
	
	Obj serviceById(Str serviceId) {
		registry.serviceById(serviceId)
	}

	Obj dependencyByType(Type dependencyType) {
		registry.dependencyByType(dependencyType)
	}

	Obj autobuild(Type type, Obj?[] ctorArgs := Obj#.emptyList) {
		registry.autobuild(type, ctorArgs)
	}

	Obj injectIntoFields(Obj service) {
		registry.injectIntoFields(service)
	}
}
