
internal const class BsErrMsgs {

	static Str routeNotFound(Uri notFound) {
		"No route found for '$notFound'"
	}
	
	static Str routeShouldBePathOnly(Uri routeBase) {
		"Route `$routeBase` must only contain a path. e.g. `/foo/bar`"
	}

	static Str routeShouldStartWithSlash(Uri routeBase) {
		"Route `$routeBase` must start with a slash. e.g. `/foo/bar`"
	}
	
	static Str fileHandlerFileNotExist(File file) {
		"Directory '${file.osPath}' does not exist"		
	}
	
	static Str fileHandlerFileNotDir(File file) {
		"File '${file.osPath}' is not a directory"
	}

	static Str fileHandlerUriNotPathOnly(Uri uri) {
		"Uri '${uri}' must only contain a path. e.g. `/foo/bar/`"
	}

	static Str fileHandlerUriMustStartWithSlash(Uri uri) {
		"Uri '${uri}' must start with a slash. e.g. `/foo/bar/`"
	}

	static Str fileHandlerUriMustEndWithSlash(Uri uri) {
		"Uri '${uri}' must end with a slash. e.g. `/foo/bar/`"
	}
	
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
		"Route `${modRel}` not found"
	}
	
	static Str errProcessorsNotErrType(Type type) {
		"Contributed ErrProcessor types must be subclasses of Err - ${type.qname}"
	}
	
	static Str bedSheetMetaDataNotInOptions() {
		"RegistryOptions does not contain BedSheetMetaData"
	}
	
	static Str cookieNotFound(Str cookieName) {
		"Could not find a cookie with the name '${cookieName}'"
	}
	
	static Str startupHostMustHaveSchemeAndAuth(Str configName, Uri host) {
		"@Config value '${configName}' must have a scheme and an auth, e.g. http://example.com - ${host}"
	}

	static Str startupHostMustNotHavePath(Str configName, Uri host) {
		"@Config value '${configName}' must NOT have a path e.g. http://example.com - ${host}"
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