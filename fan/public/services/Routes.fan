using web
using afIoc::Inject
using afIoc::Registry

** Handles routing URIs to request handler methods.
**
** If a uri can not be matched to a `Route` then a 404 HttpStatusErr is thrown.
const class Routes {
	private const static Log log := Utils.getLog(Routes#)
	
	private const Obj[] routes

	@Inject
	private const RouteMatchers routeMatchers

	@Inject
	private const ReqestHandlerInvoker handlerInvoker

	@Inject
	private const Registry registry


	internal new make(Obj[] routes, |This|? in := null) {
		in?.call(this)
		this.routes = routes
//		routes.each { Env.cur.err.printLine(it) }
	}

	internal Obj? processRequest(Uri modRel, Str httpMethod) {
		normalisedUri := normalise(modRel)
		
		response := routes.eachWhile |route| {
			routeMatch := routeMatchers.matchRoute(route, normalisedUri, httpMethod) 
			if (routeMatch == null)
				return null

			response := handlerInvoker.invokeHandler(routeMatch)
			
			return (response == false) ? null : response
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

