
** For those values that can't be placed in Config
internal mixin BsConstants {
	
	** Starts with a slash
	static const Uri	pingUrl			:= `/afBedSheetProxy/ping`
	
	static const Str	stash_err		:= "afBedSheet.err"
	
	static const Str	meta_appName	:= "afBedSheet.appName"
	static const Str	meta_appPod		:= "afBedSheet.appPod"
	static const Str	meta_appPodName	:= "afBedSheet.appPodName"
	static const Str	meta_appModule	:= "afBedSheet.appModule"
	static const Str	meta_appPort	:= "afBedSheet.appPort"
	static const Str	meta_pingProxy	:= "afBedSheet.pingProxy"
	static const Str	meta_proxyPort	:= "afBedSheet.proxyPort"
	
}
