using afIoc

@Serializable { simple = true }
class BedSheetBuilder {
	private const static Log log := Utils.getLog(BedSheetBuilder#)

	** The application name. Taken from the app pod's 'proj.name' meta, or the pod name if the meta doesn't exist.
	** Read only.
	Str appName {
		get { options["afBedSheet.appName"] }
		private set { throw Err("Read only") }
	}
	
	** The HTTP port to run the app on. Defaults to '8069'
	Int port {
		get { registryBuilder.options["afBedSheet.port"] }
		set { registryBuilder.options["afBedSheet.port"] = it }
	}

	** Returns the options from the IoC 'RegistryBuilder'.
	** Read only.
	Str:Obj? options {
		get { registryBuilder.options }
		private set { throw Err("Read only") }
	}

	** The underlying IoC 'RegistryBuilder'.
	** Read only.
	RegistryBuilder registryBuilder { private set }

	private new makeFromBob(RegistryBuilder bob) {
		this.registryBuilder = bob
		initBanner(registryBuilder)
	}
	
	** Creates a 'BedSheetBuilder'. If 
	new make(Str appName, Bool addPodDependencies := true) {
		this.registryBuilder	= RegistryBuilder()
		this.port				= 8069
		initModules(registryBuilder, appName, addPodDependencies)
		initBanner(registryBuilder)
	}

	** Builder method for 'port'.
	This setPort(Int port) {
		this.port = port
		return this
	}
	
	** Adds a module to the registry. 
	** Any modules defined with the '@SubModule' facet are also added.
	** 
	** Convenience for 'registryBuilder.addModule()'
	This addModule(Type moduleType) {
		registryBuilder.addModule(moduleType)
		return this
	}
	
	** Adds many modules to the registry
	** 
	** Convenience for 'registryBuilder.addModules()'
	This addModules(Type[] moduleTypes) {
		registryBuilder.addModules(moduleTypes)
		return this
	}
	
	** Inspects the [pod's meta-data]`docLang::Pods#meta` for the key 'afIoc.module'. This is then 
	** treated as a CSV list of (qualified) module type names to load.
	** 
	** If 'addDependencies' is 'true' then the pod's dependencies are also inspected for IoC 
	** modules.
	**  
	** Convenience for 'registryBuilder.addModulesFromPod()'
	This addModulesFromPod(Str podName, Bool addDependencies := true) {
		registryBuilder.addModulesFromPod(podName, addDependencies)
		return this		
	}
	
	** Build the IoC 'Registry'. Note the registry will still need to be started.
	Registry build() {
		registryBuilder.build
	}

	@NoDoc // for serialisation
	override Str toStr() {
		bob := registryBuilder.dup
		bob.options.remove("afIoc.bannerText")
		
		// Pod's aren't serializable
		appPod := (Pod) bob.options["afBedSheet.appPod"]
		bob.options["afBedSheet.appPodName"] = appPod.name
		bob.options.remove("afBedSheet.appPod")
		
		// we code into a Str so it's all on one line
		return Buf().writeObj(bob).flip.readAllStr.toCode
	}

	@NoDoc // for serialisation
	static BedSheetBuilder fromStr(Str str) {
		nwl := (Str) str.toBuf.readObj
		bob := (RegistryBuilder) nwl.toBuf.readObj
		
		// re-instate appPod
		appPodName	:= (Str) bob.options["afBedSheet.appPodName"]
		bob.options["afBedSheet.appPod"] = Pod.find(appPodName, true)
		bob.options.remove("afBedSheet.appPodName")
		
		return BedSheetBuilder(bob)
	}
	
	private static Void initBanner(RegistryBuilder bob) {
		bannerText := easterEgg("Alien-Factory BedSheet v${BedSheetWebMod#.pod.version}, IoC v${Registry#.pod.version}")
		bob.options["afIoc.bannerText"] = bannerText		
	}

	private static Void initModules(RegistryBuilder bob, Str moduleName, Bool transDeps) {
		Pod?  pod
		Type? mod
		
		// Pod name given...
		// lots of start up checks looking for pods and modules... 
		// see https://bitbucket.org/SlimerDude/afbedsheet/issue/1/add-a-warning-when-no-appmodule-is-passed
		if (!moduleName.contains("::")) {
			pod = Pod.find(moduleName, true)
			log.info(BsLogMsgs.bedSheetWebMod_foundPod(pod))
			mod = findModFromPod(pod)
		}

		// AppModule name given...
		if (moduleName.contains("::")) {
			mod = Type.find(moduleName, true)
			log.info(BsLogMsgs.bedSheetWebMod_foundType(mod))
			pod = mod.pod
		}

		// we're screwed! No module = no web app!
		if (mod == null)
			log.warn(BsLogMsgs.bedSheetWebMod_noModuleFound)
		
		if (pod != null) {
			if (!transDeps)
				log.info("Suppressing transitive dependencies...")
			bob.addModulesFromPod(pod.name, transDeps)
		}
		if (mod != null) {
			if (!bob.moduleTypes.contains(mod))
				bob.addModule(mod)
		}

		// A simple thing - ensure the BedSheet module is added! 
		// (transitive dependencies are added explicitly via @SubModule)
		if (!bob.moduleTypes.contains(BedSheetModule#))
			 bob.addModule(BedSheetModule#)

		regOpts := bob.options
		regOpts["afBedSheet.appPod"]	= pod
		regOpts["afBedSheet.appModule"]	= mod
		regOpts["afBedSheet.appName"]	= (pod?.meta?.get("proj.name") ?: pod?.name) ?: "Unknown"
	}

	** Looks for an 'AppModule' in the given pod. 
	private static Type? findModFromPod(Pod pod) {
		mod := null
		modName := pod.meta["afIoc.module"]
		if (modName != null) {
			mod = Type.find(modName, true)
			log.info(BsLogMsgs.bedSheetWebMod_foundType(mod))
		} else {
			// we have a pod with no module meta... so lets guess the name 'AppModule'
			mod = pod.type("AppModule", false)
			if (mod != null) {
				log.info(BsLogMsgs.bedSheetWebMod_foundType(mod))
				log.warn(BsLogMsgs.bedSheetWebMod_addModuleToPodMeta(pod, mod))
			}
		}
		// FIXME: return list of types
		return mod
	}

	private static Str easterEgg(Str title) {
		quotes := loadQuotes
		if (quotes.isEmpty || (Int.random(0..8) != 2))
			return title
		return quotes[Int.random(0..<quotes.size)]
	}

	private static Str[] loadQuotes() {
		BedSheetWebMod#.pod.file(`/res/misc/quotes.txt`).readAllLines.exclude { it.isEmpty || it.startsWith("#")}
	}
}
