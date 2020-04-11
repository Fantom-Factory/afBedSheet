using afIoc::Inject
using afIoc::Registry

** (Service) - Contribute your `Route` objects to this.
** 
** Responsible for routing URIs to request handlers.
** 
** @uses a Configuration of 'Route[]'
@NoDoc	// don't overwhelm the masses!
const mixin Routes2 {

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
				throw ArgErr(BsErrMsgs.routes_wrongType(rs[i]))
		}
		if (rs.isEmpty)
			log.warn(BsLogMsgs.routes_gotNone)

		routeTrees := Str:RouteTreeBuilder[:]
		rs.each |route| {
			
			if (route.response is Method)
				validateMethodUri(route.urlGlob, route.response)
			
			for (i := 0; i < route.httpMethods.size; ++i) {
				httpMethod	:= route.httpMethods[i]
				routeTree	:= routeTrees[httpMethod]
				if (routeTree == null)
					routeTrees[httpMethod] = routeTree = RouteTreeBuilder()
				
				routeTree.set(route.urlGlob.path, route.response)
			}
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
	
	private Void validateMethodUri(Uri url, Method method) {
		path := url.path
		numWildcards := 0
		for (i := 0; i < path.size; ++i) {
			if (path[i] == "*" || path[i] == "**")
				numWildcards++
		}
		if (numWildcards > method.params.size)
			throw ArgErr(BsErrMsgs.route_uriWillNeverMatchMethod(url, method))
		
		numMinArgs := 0
		for (i := 0; i < method.params.size; ++i) {
			if (method.params[i].hasDefault == false)
				numMinArgs++
		}
		if (numWildcards < numMinArgs)
			throw ArgErr(BsErrMsgs.route_uriWillNeverMatchMethod(url, method))
		
		return this
	}
}



@Deprecated
class RouteMatcher {
	private RouteTreeBuilder routeTreeBob
	private RouteTree?		 routeTree
	
	new make() {
		this.routeTreeBob = RouteTreeBuilder()
	}
	
	@Operator
	This set(Uri url, Obj handler) {
		routeTreeBob.set(url.path, handler)
		return this
	}
	
	@Operator
	Route3? get(Uri url) {
		routeTree = routeTreeBob.toConst

		route := routeTree.get(url.path)
		
		if (route == null)
			return null
		
		canonicalUrl := route.canonicalUrl
		
		return Route3(url, canonicalUrl, route.handler, route.wildcards)
	}    
}