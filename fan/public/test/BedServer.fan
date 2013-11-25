using concurrent::AtomicBool
using concurrent::AtomicRef
using afIoc::Registry
using afIoc::RegistryBuilder
using wisp::MemWispSessionStore
using wisp::WispSessionStore

** For testing: Allows tests to be run against an instance of 'afBedSheet' without starting the 'wisp' web server.
** Testing your web app is as simple as:
** 
**   Void testMywebApp() {
**     server   := BedServer(AppModule#).startup
**     client   := server.makeClient
**     response := client.get(`/hello`)
** 
**     verifyEq(response.statusCode, 200)
**     verifyEq(response.asStr, "Hello!")
**         
**     server.shutdown
**   }
** 
** @since 1.0.4
const class BedServer {
	private const AtomicRef		reg			:= AtomicRef()
	private const AtomicBool	started		:= AtomicBool()
	private const AtomicRef		modules		:= AtomicRef(Type#.emptyList)
	private const AtomicRef		moduleDeps	:= AtomicRef(Pod#.emptyList)

	** The 'afIoc' registry - read only.
	Registry registry {
		get { checkHasStarted; return reg.val }
		private set { reg.val = it }
	}

	** Create a instance of 'afBedSheet' with the given afIoc module (usually your web app)
	new makeWithModule(Type? iocModule := null) {
		addModulesFromDependencies(BedSheetModule#.pod)
		if (iocModule != null)
			addModule(iocModule)
	}

	** Create a instance of 'afBedSheet' with afIoc dependencies from the given pod (usually your web app)
	new makeWithPod(Pod webApp) {
		addModule(BedSheetModule#)
		addModulesFromDependencies(webApp)
	}

	** Add extra (test) modules should you wish to override behaviour in your tests
	BedServer addModule(Type iocModule) {
		checkHasNotStarted
		mods := (Type[]) modules.val
		modules.val = mods.rw.add(iocModule).toImmutable
		return this
	}

	BedServer addModulesFromDependencies(Pod dependency) {
		checkHasNotStarted
		deps := (Pod[]) moduleDeps.val
		moduleDeps.val = deps.rw.add(dependency).toImmutable
		return this
	}

	** Startup 'afBedSheet'
	BedServer startup() {
		checkHasNotStarted
		bannerText := "Alien-Factory BedServer v${typeof.pod.version}, IoC v${Registry#.pod.version}"
		
		bob := RegistryBuilder()
		
		((Pod[]) moduleDeps.val).each |pod| {
			bob.addModulesFromDependencies(pod)			
		}
		
		mods := (Type[]) modules.val
		bob.addModules(mods)

		module := ((Type[]) modules.val).first
		bedSheetMetaData := BedSheetMetaDataImpl(module?.pod, module, [:])
		
		registry = bob.build(["bannerText":bannerText, "bedSheetMetaData":bedSheetMetaData]).startup
		
		started.val = true
		return this
	}

	** Shutdown 'afBedSheet'
	BedServer shutdown() {
		checkHasStarted
		registry.shutdown
		reg.val = null
		started.val = false
		modules.val	= Type#.emptyList
		return this
	}
	
	** Create a `BedClient` that makes requests against this server
	BedClient makeClient() {
		checkHasStarted
		return BedClient(this)
	}

	// ---- Registry Methods ----
	
	** Helper method - tap into BedSheet's afIoc registry
	Obj serviceById(Str serviceId) {
		checkHasStarted
		return registry.serviceById(serviceId)
	}

	** Helper method - tap into BedSheet's afIoc registry
	Obj dependencyByType(Type dependencyType) {
		checkHasStarted
		return registry.dependencyByType(dependencyType)
	}

	** Helper method - tap into BedSheet's afIoc registry
	Obj autobuild(Type type, Obj?[] ctorArgs := Obj#.emptyList) {
		checkHasStarted
		return registry.autobuild(type, ctorArgs)
	}

	** Helper method - tap into BedSheet's afIoc registry
	Obj injectIntoFields(Obj service) {
		checkHasStarted
		return registry.injectIntoFields(service)
	}
	
	// ---- helper methods ----
	
	** as called by BedClients - if no reg then we must have been shutdown
	internal Void checkHasNotShutdown() {
		if (reg.val == null)
			throw Err("${BedServer#.name} has been shutdown!")
	}

	private Void checkHasStarted() {
		if (!started.val)
			throw Err("${BedServer#.name} has not yet started!")
	}

	private Void checkHasNotStarted() {
		if (started.val)
			throw Err("${BedServer#.name} has not already been started!")
	}
}

