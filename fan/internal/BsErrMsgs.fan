
internal const class BsErrMsgs {

	static Str routeNotFound(Uri notFound) {
		"No route found for '$notFound'"
	}
	
	static Str routeShouldBePathOnly(Uri routeBase) {
		"Route '$routeBase' must only contain a path. e.g. `/foo/bar`"
	}

	static Str routeShouldStartWithSlash(Uri routeBase) {
		"Route '$routeBase' must start with a slash. e.g. `/foo/bar`"
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
		"Uri '${uri}' must start with a path. e.g. `/foo/bar/`"
	}

	static Str fileHandlerUriMustEndWithSlash(Uri uri) {
		"Uri '${uri}' must end with a path. e.g. `/foo/bar/`"
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
	
	static Str requestLogFilterDirCannotBeNull() {
		"Please contribute a RequestLogFilter dir! \nExample, conf[ConfigIds.requestLogDir] = `/my/log/dir/`.toFile"
	}

}