
** For those values that can't be placed in Config
internal mixin BsConstants {
	
	** Starts with a slash
	static const Uri	pingUrl				:= `/afBedSheet/ping`
	static const Uri	killUrl				:= `/afBedSheet/kill`
	static const Uri	restartUrl			:= `/afBedSheet/restart`
	
	static const Str	stash_err			:= "afBedSheet.err"
	
	static const Str	meta_appName		:= "afBedSheet.appName"
	static const Str	meta_appPod			:= "afBedSheet.appPod"
	static const Str	meta_appPodName		:= "afBedSheet.appPodName"
	static const Str	meta_appModule		:= "afBedSheet.appModule"
	static const Str	meta_appPort		:= "afBedSheet.appPort"
	static const Str	meta_watchdog		:= "afBedSheet.watchdog"
	static const Str	meta_watchdogPort	:= "afBedSheet.watchdogPort"
	static const Str	meta_watchAllPods	:= "afBedSheet.watchAllPods"
	
}
