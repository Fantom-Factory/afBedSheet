using web
using afIoc::Inject
using afIoc::Registry

**
** Router handles routing URIs to method handlers.
**
** BedSheet takes the stance that any Err encountered whilst finding or invoking a handler should 
** cause a 404. If a route doesn't exist, or the wrong params were supplied, then that URI is 
** clearly wrong and should be reported as such.   
const class Routes {
	private const static Log log := Utils.getLog(Routes#)
	
	private const Obj[] routes

	@Inject
	private const RouteMatcherSource routeMatcherSource
	
	@Inject
	private const RouteHandler routeHandler
	
	@Inject
	private const Registry registry
	
	
	new make(Obj[] routes, |This|? in := null) {
		in?.call(this)
		this.routes = routes
	}

	internal Obj processRequest(Uri modRel, Str httpMethod) {
		normalisedUri := normalise(modRel)
		
		return routes.eachWhile |route| {
			
			routeMatcher := routeMatcherSource.get(route.typeof)
			
			routeMatch := routeMatcher.match(route, normalisedUri, httpMethod) 
			if (routeMatch == null) {
				return null
			}
			
//			log.debug("Matched to uri `$routeMatch.routeBase` for $routeMatch.handler.qname")
			
			// save the routeMatch so it can be picked up by `Request` for routeBase() & routeMod()
			webReq.stash["bedSheet.routeMatch"] = routeMatch

			result := routeHandler.handle(routeMatch)
			
			return (result == false) ? null : result 
			
		} ?: throw RouteNotFoundErr(BsMsgs.routeNotFound(modRel))
		
		// TODO: if req uri is '/' and no routes have been defined, route to a default 'BedSheet Welcome' page
		// TODO: have this as a contributed route, after *! Use config to turn on and off
	}
	
	private Uri normalise(Uri uri) {
		if (!uri.isPathAbs)
			uri = `/` + uri
		return uri
	}
	
	private WebReq webReq() {
		registry.dependencyByType(WebReq#)
	}	
}

