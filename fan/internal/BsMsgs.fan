
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
		"Handler $handler.qname has wrong number of params to handle `$uri`"
	}
	
}