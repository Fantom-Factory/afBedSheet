
internal const class BsErrMsgs {

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
	
	static Str bedSheetMetaDataNotInOptions() {
		"RegistryOptions does not contain key 'bedSheetMetaData'"
	}
	
	static Str cookieNotFound(Str cookieName) {
		"Could not find a cookie with the name '${cookieName}'"
	}
	
	// ---- Startup Validation ----
	
	static Str startupHostMustHaveSchemeAndHost(Str configName, Uri host) {
		"@Config value '${configName}' must have a scheme and a host part, e.g. http://example.com - ${host}"
	}

	static Str startupHostMustNotHavePath(Str configName, Uri host) {
		"@Config value '${configName}' must NOT have a path e.g. http://example.com - ${host}"
	}
	
	// ---- FileHandler ----
	
	static Str fileHandler_dirNotFound(File file) {
		"Directory '${file.normalize.osPath}' does not exist"		
	}
	
	static Str fileHandler_notDir(File file) {
		"File '${file.normalize.osPath}' is not a directory"
	}

	static Str fileHandler_urlNotPathOnly(Uri uri, Uri example) {
		"Uri '${uri}' must only contain a path. e.g. `${example}`"
	}

	static Str fileHandler_urlMustStartWithSlash(Uri uri, Uri example) {
		"Uri '${uri}' must start with a slash. e.g. `${example}`"
	}

	static Str fileHandler_urlMustEndWithSlash(Uri uri) {
		"Uri '${uri}' must end with a slash. e.g. `/foo/bar/`"
	}
	
	static Str fileHandler_urlNotMapped(Uri uri) {
		"Asset URI `${uri}` does NOT map to any known FileHandler prefixes."
	}
	
	static Str fileHandler_notFile(File file) {
		"File `${file.normalize.osPath}` is a directory!?"
	}
	
	static Str fileHandler_fileNotFound(File file) {
		"File `${file.normalize.osPath}` does not exist."
	}
	
	static Str fileHandler_fileNotMapped(File file) {
		"File `${file.normalize.osPath}` does NOT map to any known FileHandler directories."
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