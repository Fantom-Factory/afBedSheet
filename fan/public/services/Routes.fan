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
	private const ReqestHandlerInvoker handlerInvoker
	
	@Inject
	private const Registry registry
	
	
	new make(Obj[] routes, |This|? in := null) {
		in?.call(this)
		this.routes = routes
//		routes.each { Env.cur.err.printLine(it) }
	}

	internal Obj? processRequest(Uri modRel, Str httpMethod) {
		normalisedUri := normalise(modRel)
		
		response := routes.eachWhile |route| {
			routeMatcher := routeMatcherSource.get(route.typeof)
			
			routeMatch := routeMatcher.match(route, normalisedUri, httpMethod) 
			if (routeMatch == null)
				return null

			result := handlerInvoker.invokeHandler(routeMatch)
			
			return (result == false) ? null : result
		}
		
		// TODO: if no routes have been defined, route to a default 'BedSheet Welcome' page. Use config to turn on and off
		if (response == null)
			throw HttpStatusErr(404, BsMsgs.route404(modRel, httpMethod))

		return response
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

