
internal const class BsMsgs {

	static Str routeNotFound(Uri notFound) {
		"No route found for '$notFound'"
	}
	
	static Str routeShouldBePathOnly(Uri routeBase) {
		"Routing path '$routeBase' must only contain a path. e.g. `/foo/bar`"
	}

	static Str routeShouldStartWithSlash(Uri routeBase) {
		"Routing path '$routeBase' must start with a slash. e.g. `/foo/bar`"
	}
	
	static Str routesCanNotBeNested(Uri inner, Uri outer) {
		"Route `$inner` can not be nested under `$outer`"
	}

	static Str routeAlreadyAdded(Uri route, Method hander) {
		"Route `$route` has already been assigned to hander $hander.qname"
	}

	static Str handlerArgSizeMismatch(Method handler, Uri uri) {
		// purposely do not use qname - that's too much info for a public message.
		"Handler '$handler.name' can not handle `$uri`"
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
	
	static Str handlersCanNotBeVoid(Method method) {
		"Handler $method.qname is not allowed to be Void. If processing is complete, return 'true' instead."
	}

	static Str handlersCanNotReturnNull(Method method) {
		"Handler $method.qname is not allowed to return null. If processing is complete, return 'true' instead."
	}
}