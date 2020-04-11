
internal const class BsErrMsgs {

	// ---- Generic ----

	static Str urlMustBePathOnly(Uri url, Uri example) {
		"URL `${url}` must ONLY be a path. e.g. `${example}`"
	}

	static Str urlMustStartWithSlash(Uri url, Uri example) {
		"URL `${url}` must start with a slash. e.g. `${example}`"
	}

	static Str urlMustEndWithSlash(Uri url, Uri example) {
		"URL `${url}` must end with a slash. e.g. `${example}`"
	}

	static Str urlMustNotEndWithSlash(Uri url, Uri example) {
		"URL `${url}` must NOT end with a slash. e.g. `${example}`"
	}

	static Str fileIsDirectory(File file) {
		"File `${file.normalize.osPath}` is a directory!?"
	}
	
	static Str fileIsNotDirectory(File file) {
		"File `${file.normalize.osPath}` is NOT a directory!?"
	}
	
	static Str fileNotFound(File file) {
		type := file.isDir ? "Directory" : "File"
		return "${type} `${file.normalize.osPath}` does not exist!"
	}

	static Str directoryListingNotAllowed(Uri? url) {
		"Directory listing not allowed: ${url}"
	}

	// ---- Routes ----

	static Str route_notFound(Uri notFound) {
		"No route found for '$notFound'"
	}
	
	static Str route_shouldBePathOnly(Uri routeBase) {
		"Route `$routeBase` must only contain a path. e.g. `/foo/bar`"
	}

	static Str route_shouldStartWithSlash(Uri routeBase) {
		"Route `$routeBase` must start with a slash. e.g. `/foo/bar`"
	}

	static Str route_uriWillNeverMatchMethod(Uri url, Method method) {
		"Route URL `${url}` will never match method ${method.parent.qname} " + method.signature.replace("sys::", "")
	}

	static Str routes_wrongType(Obj obj) {
		"Contribution is NOT of type ${Route#.name} - ${obj.typeof.qname} - ${obj}"
	}

	// ---- Startup Validation ----
	
	static Str startup_hostMustHaveSchemeAndHost(Str configName, Uri host) {
		"@Config value '${configName}' must have a scheme and a host part, e.g. http://example.com - ${host}"
	}

	static Str startup_hostMustNotHavePath(Str configName, Uri host) {
		"@Config value '${configName}' must NOT have a path e.g. http://example.com - ${host}"
	}
	
	// ---- Handlers ----
		
	static Str fileHandler_urlNotMapped(Uri url) {
		"Asset URL `${url}` does NOT map to any known FileHandler prefixes."
	}
	
	static Str fileHandler_fileNotMapped(File file) {
		"File `${file.normalize.osPath}` does NOT map to any known FileHandler directories."
	}
	
	static Str podHandler_urlNotMapped(Uri localUrl, Uri prefix) {
		"Pod URL `${localUrl}` does NOT start with the handler prefix `${prefix}`"
	}

	static Str podHandler_urlNotFanScheme(Uri podUrl) {
		"Pod URL `${podUrl}` must have the scheme `fan:` e.g. `fan://icons/x256/flux.png`"
	}

	static Str podHandler_urlDoesNotResolve(Uri podUrl) {
		"Pod URL `${podUrl}` does NOT resolve - does it exist?"
	}

	static Str podHandler_urlNotFile(Uri podUrl, Obj? obj) {
		"Pod URL `${podUrl}` does NOT resolve to a File, but a ${obj?.typeof?.qname} - ${obj}"
	}

	static Str podHandler_disabled() {
		"Pod resource handling has been disabled - config ID '${BedSheetConfigIds.podHandlerBaseUrl}' has been set to null"
	}

	static Str podHandler_notInWhitelist(Str podPath) {
		"Pod URL `${podPath}` does not match any whitelist filter"
	}
	
	static Str srcMapHandler_disabled() {
		"Pod source handling has been disabled - config ID '${BedSheetConfigIds.srcMapHandlerBaseUrl}' has been set to null"
	}

	// ---- Other ----

	static Str valueEncoding_buggered(Obj? value, Type toType) {
		stripSys("Could not convert '$value' to ${toType.qname}")
	}

	static Str oneShotLock_violation(Str because) {
		"Method may no longer be invoked - $because"
	}
	
	static Str route404(Uri modRel, Str httpMethod) {
		"Route `${modRel}` not found ($httpMethod)"
	}
	
	static Str errProcessors_notErrType(Type type) {
		"Contributed ErrProcessor types must be subclasses of Err - ${type.qname}"
	}
	
	static Str cookieNotFound(Str cookieName) {
		"Could not find a cookie with the name '${cookieName}'"
	}
	
	static Str appRestarter_couldNotLaunch(Str appModule) {
		"Could not launch external process for proxied Web App '$appModule'\n"
	}
	
	static Str stripSys(Str str) {
		str.replace("sys::", "")
	}
}