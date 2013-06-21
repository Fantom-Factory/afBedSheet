
**
** Route maps a URI to a method handler. All uri's are treated as case-insensitive.
** 
** All handler classes are [autobuilt]`afIoc::Registry.autobuild`. If the class is 'const', the 
** instance is cached for future use.
** 
** Nicked and adapted form 'draft'
**
const class Route {

	** The URI this route matches. Always starts and ends with a slash.
	const Uri routeBase

	** Method handler for this route. 
	const Method handler

	** HTTP method used for this route
	const Str httpMethod

	private const Str[] matchingPath
	private const Regex httpMethodGlob
	
	new make(Uri routeBase, Method handler, Str httpMethod := "GET") {
	    if (!routeBase.isPathOnly)
			throw BedSheetErr(BsMsgs.routeShouldBePathOnly(routeBase))
	    if (!routeBase.isPathAbs)
			throw BedSheetErr(BsMsgs.routeShouldStartWithSlash(routeBase))

		this.routeBase 		= routeBase.plusSlash
		this.httpMethod		= httpMethod.upper.trim
		this.handler 		= handler
		this.matchingPath 	= routeBase.path.map { it.lower }
		this.httpMethodGlob	= Regex.glob(this.httpMethod)
	}

	** Match this route against the request arguments, returning a list of Str arguments. Returns
	** 'null' if no match.
	internal RouteMatch? match(Uri uri, Str httpMethod) {
		if (!httpMethodGlob.matches(httpMethod))
			return null

		uriPath 	:= uri.path
		actualBase	:= ``	// need to build up the actualBase for a case-insensitive Uri.relTo()
		match		:= matchingPath.all |path, i| { 
			actualBase = actualBase.plusSlash.plusName(uriPath[i]) 
			return path == uriPath[i].lower
		}
		if (!match) 
			return null

		rel:= uri.relTo(actualBase)
		return RouteMatch(routeBase, rel, handler)
	}
}
