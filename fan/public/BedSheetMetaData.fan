
** @Inject - MetaData for BedSheet, gleaned from startup.
const mixin BedSheetMetaData {
	
	** The pod that contains the initial 'AppModule'.
	abstract Pod? 	appPod()
	
	** The 'AppModule'.
	abstract Type?	appModule()	
}

internal const class BedSheetMetaDataImpl : BedSheetMetaData {
	
	** The pod that contains the initial 'AppModule'.
	override const Pod? 	appPod
	
	** The 'AppModule'.
	override const Type?	appModule
	
	internal new make(Pod? appPod, Type? appModule) {
		this.appPod = appPod
		this.appModule = appModule
	}
}
