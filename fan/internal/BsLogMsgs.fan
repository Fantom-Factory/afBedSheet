
internal const class BsLogMsgs {
	
	// ---- ProxyMod ------------------------------------------------------------------------------
	
	static Str proxyModStarting(Int proxyPort) {
		"Starting BedSheet Proxy on port $proxyPort"
	}	

	// ---- AppRestarter --------------------------------------------------------------------------

	static Str appRestarterCachedPodTimestamps(Int noOfPods) {
		"Cached the timestamps of ${noOfPods} pods"
	}	

	static Str appRestarterLauchingApp(Str appModule, Int port) {
		"Launching BedSheet WebApp '$appModule' on port $port\n"
	}	

	static Str appRestarterKillingApp(Str appModule) {
		"Killing BedSheet WebApp '$appModule'"
	}	

	static Str appRestarterPodUpdatd(Pod pod, Duration timeDiff) {
		"Pod '$pod.name' pod was updated $timeDiff.abs.toLocale ago"
	}

	// ---- AppDestroyer --------------------------------------------------------------------------
	
	static Str appDestroyerStarted(Duration pingInterval) {
		"Starting AppDestroyer. Pinging proxy every ${pingInterval}..."
	}

	static Str appDestroyerPingNotOk(Int resCode, Str resMsg) {
		"Proxy ping returned $resCode $resMsg"
	}

	static Str appDestroyerPingOk() {
		"Proxy ping returned 200 OK - resetting strike count."
	}

	static Str appDestroyerStrikeOut(Int strikesLeft) {
		"Proxy has $strikesLeft strike(s) left before this app terminates"
	}

	static Str appDestroyerDESTROY(Int strikes) {
		"Proxy is down. TERMINATING WEB APP WITH EXTREME PREDUDICE!!!"
	}

	// ---- BedSheetWebMod ------------------------------------------------------------------------

	static Str bedSheetWebModStarting(Str appModule, Int port) {
		"Starting BedSheet WebApp '$appModule' on port $port"
	}

	static Str bedSheetWebModFoundPod(Pod pod) {
		" - Found pod '$pod.name'"
	}

	static Str bedSheetWebModFoundType(Type type) {
		" - Found type '$type.qname' "
	}

	static Str bedSheetWebModStopping(Str appModule) {
		"\"Goodbye!\" from afBedSheet!"
	}
}
