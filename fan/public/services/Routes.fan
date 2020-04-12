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
			
			// special RouteMethod handling to define handlers for methods with default arguments
			if (route._response is RouteMethod) {
				rMethod	  := (RouteMethod) route._response
				defRoutes := route._defRoutes(rMethod.method)
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
		routeMatch := routeTrees[httpRequest.httpMethod]?.get(httpRequest.urlPath)

		if (routeMatch != null) {
			httpRequest.stash["afBedSheet.routeMatch"] = routeMatch
			
			response	 := routeMatch.response
			canonicalUrl := routeMatch.canonicalUrl

			// TODO use a canonicalUrlRedirect strategy
			if (httpRequest.url.pathOnly != canonicalUrl)
				response = Redirect.movedTemporarily(canonicalUrl)
			
			return responseProcessors.processResponse(response)
		}
		
		return false
	}
	
	private Void addRoute(Str:RouteTreeBuilder routeTrees, Route route) {
		httpMethods := route._httpMethod.upper.split
		for (i := 0; i < httpMethods.size; ++i) {
			httpMethod	:= httpMethods[i]
			routeTree	:= routeTrees[httpMethod]
			if (routeTree == null)
				routeTrees[httpMethod] = routeTree = RouteTreeBuilder()
			
			routeTree.set(route._urlGlob.path, route._response)
		}
	}
}
