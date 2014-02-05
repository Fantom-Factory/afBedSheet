using concurrent::AtomicRef

** (Service) - MetaData gleaned from startup, such as the initial 'AppModule'.
const mixin BedSheetMetaData {
	
	** The pod that contains the initial 'AppModule'.
	abstract Pod? 	appPod()
	
	** The 'AppModule'.
	abstract Type?	appModule()	
	
	** The port BedSheet is running under.
	abstract Int	port()	
	
	** The options BedSheet was started with
	abstract [Str:Obj] 	options()
	
	** Returns the from the application's pod meta, or "Unknown" if no pod was found.
	virtual Str appName() {
		appPod?.meta?.get("proj.name") ?: "Unknown"
	}
}

internal const class BedSheetMetaDataImpl : BedSheetMetaData {

	override const Pod? 		appPod
	override const Type?		appModule
	override const Int			port
	override const [Str:Obj] 	options
	
	internal new make(Pod? appPod, Type? appModule, Int port, [Str:Obj] options) {
		this.appPod 	= appPod
		this.appModule 	= appModule
		this.port 		= port
		this.options 	= options.toImmutable
	}
}
