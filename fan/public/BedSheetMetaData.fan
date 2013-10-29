
** MetaData for BedSheet, gleaned from startup.
const class BedSheetMetaData {
	
	** The pod that contains the initial 'AppModule'.
	const Pod? 	appPod
	
	** The 'AppModule'.
	const Type?	appModule
	
	internal new make(Pod? appPod, Type? appModule) {
		this.appPod = appPod
		this.appModule = appModule
	}
}
