
// FIXME killme BsLogMsgs
internal const class BsLogMsgs {

	// ---- AppRestarter --------------------------------------------------------------------------

	static Str appRestarter_lauchingApp(Str appModule, Int port) {
		"Launching BedSheet WebApp '$appModule' on port $port"
	}	

	static Str appRestarter_process(Str cmd) {
		"Executing external process:\n\n${cmd}\n"
	}	

	static Str appRestarter_killingApp(Str appModule) {
		"Killing BedSheet WebApp '$appModule'"
	}

	static Str appRestarter_canNotProxyScripts(Str podName) {
		"Can not proxy applications run from a script - ${podName}"
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

	static Str bedSheetWebMod_starting(Str appModule, Int port) {
		"Starting Bed App '$appModule' on port $port"
	}

	static Str bedSheetWebMod_foundPod(Pod pod) {
		"Found pod '$pod.name'"
	}

	static Str bedSheetWebMod_foundType(Type type) {
		"Found mod '$type.qname' "
	}

	static Str bedSheetWebMod_addModuleToPodMeta(Pod pod, Type mod) {
		"Pod '${pod.name}' should define the following meta - \"afIoc.module\" : \"${mod.qname}\""
	}

	static Str bedSheetWebMod_noModuleFound() {
		"Could not find any AppModules!"
	}

	static Str bedSheetWebMod_started(Str appName, Version? ver, Uri host) {
		"\n\nBed App '$appName' v" + (ver ?: "???") + " listening on ${host}\n"
	}
	
	static Str bedSheetWebMod_stopping(Str appModule) {
		"BedSheet says, \"Farewell!\""
	}

	// ---- Other ---------------------------------------------------------------------------------
	
	static Str routes_gotNone() {
		"No contributions have been made to the Routes service!"
	}

	static Str requestLog_enabled(File logDir) {
		"HTTP Request Logging is enabled --> ${logDir.normalize.osPath}"
	}
	
	static Str safeOutStream_socketErr(Err err) {
		"Could not write to socket (Application Protocol Error) - ${err.msg}"
	}
}
