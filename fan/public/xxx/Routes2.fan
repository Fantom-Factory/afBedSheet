using afIoc::Inject
using afIoc::Registry

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
				throw ArgErr(BsErrMsgs.routes_wrongType(rs[i]))
		}
		if (rs.isEmpty)
			log.warn(BsLogMsgs.routes_gotNone)

		routeTrees := Str:RouteTreeBuilder[:]
		rs.each |route| {
			
			if (route.response is Method) {
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

echo("$httpRequest.url -> ${urlMatch?.canonicalUrl} + ${urlMatch?.wildcards}")

		if (urlMatch != null) {
			response	 := urlMatch.handler
			canonicalUrl := urlMatch.canonicalUrl

			// FIXME - this is cool - but breaks tests!
//			if (httpRequest.url.pathOnly != canonicalUrl)
//				response = Redirect.movedTemporarily(canonicalUrl)
			
			if (response is Method)
				response = MethodCall(urlMatch.handler, urlMatch.wildcards)
			
			return responseProcessors.processResponse(response)
		}
		
		return false
	}
	
	private Void addRoute(Str:RouteTreeBuilder routeTrees, Route route) {
		for (i := 0; i < route.httpMethods.size; ++i) {
			httpMethod	:= route.httpMethods[i]
			routeTree	:= routeTrees[httpMethod]
			if (routeTree == null)
				routeTrees[httpMethod] = routeTree = RouteTreeBuilder()
			
			routeTree.set(route.urlGlob.path, route.response)
		}
	}
}
