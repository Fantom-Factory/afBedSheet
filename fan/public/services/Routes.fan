using afIoc::Inject
using afIoc::Registry

** (Service) - Contribute your `Route` objects to this.
** 
** Responsible for routing URIs to request handlers.
** 
** @uses a Configuration of 'Route[]'
@NoDoc	// don't overwhelm the masses!
const mixin Routes {

	** The ordered list of routes
	abstract Route[] routes()

	** Returns true if the HTTP request was handled.
	@NoDoc	// not for public use 
	abstract Bool processRequest(HttpRequest httpRequest)
}

internal const class RoutesImpl : Routes {
	@Inject	private const Log					log
	@Inject	private const ResponseProcessors	responseProcessors
			private const Str:RouteTree			routeTrees

	override const Route[] routes

	internal new make(Obj[] routes, |This|? in := null) {
		in?.call(this)
		rs := (Route[]) routes.flatten
		
		for (i := 0; i < rs.size; ++i) {
			if (rs[i] isnot Route)
				throw ArgErr("Contribution is NOT of type ${Route#.name} - ${rs[i].typeof.qname} - ${rs[i]}")
		}
		if (rs.isEmpty)
			log.warn(BsLogMsgs.routes_gotNone)

		routeTrees := Str:RouteTreeBuilder[:]
		rs.each |route| {
			
			if (route._response is Method) {
				defRoutes := route._defRoutes
				if (defRoutes != null) {
					defRoutes.each {
						addRoute(routeTrees, it)
					}
				}
			}
			
			addRoute(routeTrees, route)
		}

		this.routes		= rs.toImmutable
		this.routeTrees = routeTrees.map { it.toConst }
	}
	
	override Bool processRequest(HttpRequest httpRequest) {
		urlMatch := routeTrees[httpRequest.httpMethod]?.get(httpRequest.urlPath)

		if (urlMatch != null) {
			response	 := urlMatch.handler
			canonicalUrl := urlMatch.canonicalUrl

			// TODO use a canonicalUrlRedirect strategy
			if (httpRequest.url.pathOnly != canonicalUrl)
				response = Redirect.movedTemporarily(canonicalUrl)
			
			if (response is Method)
				response = MethodCall(urlMatch.handler, urlMatch.wildcards)
			
			return responseProcessors.processResponse(response)
		}
		
		return false
	}
	
	private Void addRoute(Str:RouteTreeBuilder routeTrees, Route route) {
		for (i := 0; i < route._httpMethods.size; ++i) {
			httpMethod	:= route._httpMethods[i]
			routeTree	:= routeTrees[httpMethod]
			if (routeTree == null)
				routeTrees[httpMethod] = routeTree = RouteTreeBuilder()
			
			routeTree.set(route._urlGlob.path, route._response)
		}
	}
}
