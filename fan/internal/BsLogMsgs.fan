
internal const class BsLogMsgs {
	
	// ---- ProxyMod ------------------------------------------------------------------------------
	
	static Str proxyModStarting(Int proxyPort) {
		"Starting BedSheet Proxy on port $proxyPort"
	}	

	// ---- AppRestarter --------------------------------------------------------------------------

	static Str appRestarter_cachedPodTimestamps(Int noOfPods) {
		"Cached the timestamps of ${noOfPods} pods"
	}	

	static Str appRestarter_lauchingApp(Str appModule, Int port) {
		"Launching BedSheet WebApp '$appModule' on port $port"
	}	

	static Str appRestarter_process(Str cmd) {
		"Executing external process:\n\n${cmd}\n"
	}	

	static Str appRestarter_killingApp(Str appModule) {
		"Killing BedSheet WebApp '$appModule'"
	}	

	static Str appRestarter_podUpdatd(Str podName, Duration timeDiff) {
		"Pod '$podName' pod was updated $timeDiff.abs.toLocale ago"
	}

	// ---- AppDestroyer --------------------------------------------------------------------------
	
	static Str appDestroyer_started(Duration pingInterval) {
		"Starting AppDestroyer. Pinging proxy every ${pingInterval}..."
	}

	static Str appDestroyer_pingNotOk(Int resCode, Str resMsg) {
		"Proxy ping returned $resCode $resMsg"
	}

	static Str appDestroyer_pingOk() {
		"Proxy ping returned 200 OK - resetting strike count."
	}

	static Str appDestroyer_strikeOut(Int strikesLeft) {
		"Proxy has $strikesLeft strike(s) left before this app terminates"
	}

	static Str appDestroyer_DESTROY(Int strikes) {
		"Proxy is down. TERMINATING WEB APP WITH EXTREME PREDUDICE!!!"
	}

	// ---- BedSheetWebMod ------------------------------------------------------------------------

	static Str bedSheetWebModStarting(Str appModule, Int port) {
		"Starting Bed App '$appModule' on port $port"
	}

	static Str bedSheetWebModFoundPod(Pod pod) {
		"Found pod '$pod.name'"
	}

	static Str bedSheetWebModFoundType(Type type) {
		"Found mod '$type.qname' "
	}

	static Str bedSheetWebModAddModuleToPodMeta(Pod pod, Type mod) {
		"Pod '${pod.name}' should define the following meta - \"afIoc.module\" : \"${mod.qname}\""
	}

	static Str bedSheetWebModNoModuleFound() {
		"Could not find any AppModules!"
	}

	static Str bedSheetWebModStarted(Str appName, Uri host) {
		"\n\nBed App '$appName' listening on ${host}\n"
	}
	
	static Str bedSheetWebModStopping(Str appModule) {
		"\"Goodbye!\" from afBedSheet!"
	}

	// ---- Other ---------------------------------------------------------------------------------
	
	static Str routesGotNone() {
		"No contributions have been made to the Routes service!"
	}

	static Str requestLogEnabled(File logDir) {
		"HTTP Request Logging is enabled --> ${logDir.normalize.osPath}"
	}
	
}
