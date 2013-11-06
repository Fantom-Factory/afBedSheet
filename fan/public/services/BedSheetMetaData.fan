using concurrent::AtomicRef

** (Service) - MetaData for BedSheet, gleaned from startup.
const mixin BedSheetMetaData {
	
	** The pod that contains the initial 'AppModule'.
	abstract Pod? 	appPod()
	
	** The 'AppModule'.
	abstract Type?	appModule()	
	
	** The options BedSheet was started with
	abstract [Str:Obj] 	options()
}

internal const class BedSheetMetaDataImpl : BedSheetMetaData {

	override const Pod? 		appPod
	override const Type?		appModule
	override const [Str:Obj] 	options
	
	internal new make(Pod? appPod, Type? appModule, [Str:Obj] options) {
		this.appPod 	= appPod
		this.appModule 	= appModule
		this.options 	= options.toImmutable
	}
}