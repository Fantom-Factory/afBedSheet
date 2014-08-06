
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

	// ---- Routes ----

	static Str routeNotFound(Uri notFound) {
		"No route found for '$notFound'"
	}
	
	static Str routeShouldBePathOnly(Uri routeBase) {
		"Route `$routeBase` must only contain a path. e.g. `/foo/bar`"
	}

	static Str routeShouldStartWithSlash(Uri routeBase) {
		"Route `$routeBase` must start with a slash. e.g. `/foo/bar`"
	}

	static Str routeUriWillNeverMatchMethod(Regex routeRegex, Uri? routeGlob, Method method) {
		routeGlob != null
			? "Route Uri `${routeGlob}` will never match method ${method.parent.qname} " + method.signature.replace("sys::", "")
			: "Route Regex ${routeRegex} will never match method ${method.parent.qname} " + method.signature.replace("sys::", "")
	}

	static Str routes_wrongType(Obj obj) {
		"Contribution is NOT of type ${Route#.name} - ${obj.typeof.qname} - ${obj}"
	}

	// ---- Other ----

	static Str valueEncodingBuggered(Obj value, Type toType) {
		"Could not convert $value to ${toType.qname}"
	}

	static Str valueEncodingNotFound(Type valType) {
		"Could not find either a ValueEncoder or a suitable fromStr() static factory method for ${valType.qname}"
	}
	
	static Str oneShotLockViolation(Str because) {
		"Method may no longer be invoked - $because"
	}
	
	static Str route404(Uri modRel, Str httpMethod) {
		"Route `${modRel}` not found ($httpMethod)"
	}
	
	static Str errProcessorsNotErrType(Type type) {
		"Contributed ErrProcessor types must be subclasses of Err - ${type.qname}"
	}
	
	static Str cookieNotFound(Str cookieName) {
		"Could not find a cookie with the name '${cookieName}'"
	}
	
	static Str appRestarter_couldNotLaunch(Str appModule) {
		"Could not launch external process for proxied Web App '$appModule'\n"
	}	

	// ---- Startup Validation ----
	
	static Str startupHostMustHaveSchemeAndHost(Str configName, Uri host) {
		"@Config value '${configName}' must have a scheme and a host part, e.g. http://example.com - ${host}"
	}

	static Str startupHostMustNotHavePath(Str configName, Uri host) {
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

	// ---- Pipeline Service Messages -------------------------------------------------------------

	static Str pipelineTypeMustBePublic(Str thing, Type type) {
		"${thing} ${type.qname} must be public"
	}

	static Str pipelineTypeMustBeMixin(Str thing, Type type) {
		"${thing} ${type.qname} must be a mixin"
	}

	static Str pipelineTypeMustNotDeclareFields(Type type) {
		"Pipeline type ${type.qname} must not declare fields: " + type.fields.join(", ") { it.name }
	}

	static Str pipelineTerminatorMustExtendPipeline(Type pipelineType, Type terminatorType) {
		"Pipeline Terminator ${terminatorType.qname} must extend Pipeline mixin ${pipelineType.qname}"
	}

	static Str middlewareMustExtendMiddleware(Type middlewareType, Type middlewareImplType) {
		"Middleware ${middlewareImplType.qname} must extend Middleware mixin ${middlewareType.qname}"
	}
	
	static Str middlewareMustDeclareMethod(Type middlewareType, Str methodSig) {
		"Middleware ${middlewareType.qname} must declare method : ${methodSig}"
	}
}