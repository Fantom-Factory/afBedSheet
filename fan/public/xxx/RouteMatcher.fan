
class RouteMatcher {
	private RouteTree routeTree
	
	new make() {
		this.routeTree = RouteTree()
	}
	
	@Operator
	This set(Uri url, Obj handler) {
		if (url.pathStr.contains("//"))	throw ArgErr("That's nasty! $url")

		// FIXME check for empty path
		
		routeTree.set(url.path, handler)
		return this
	}
	
	@Operator
	Route2? get(Uri url) {
		route := routeTree.get(url.path)
		
		if (route == null)
			return null
		
		canonicalUrl := route.canonicalUrl
		
		return Route2(url, canonicalUrl, route.handler, route.wildcards, route.remaining)
	}    
}
