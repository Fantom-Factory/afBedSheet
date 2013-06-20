using web
using afIoc::Inject
using afIoc::Registry

**
** Router handles routing URIs to method handlers.
**
** BedSheet takes the stance that any Err encountered whilst finding or invoking a handler should 
** cause a 404. If a route doesn't exist, or the wrong params were supplied, then that URI is 
** clearly wrong and should be reported as such.   
// Maybe abstract this away so routing becomes pluggable?
const class RouteSource {
	const Route[] routes

	@Inject @Config { id="afBedSheet.welcomePage" }
	@Deprecated	 //- no longer used
	private const Uri? welcomePage

	@Inject
	private const RouteHandler routeHandler
	
	@Inject
	private const Registry registry
	
	
	new make(Route[] routes, |This|? in := null) {
		in?.call(this)

		dups := Route[,]
		routes.each |route| {
//			dup	:= dups.find { route.routeBase.toStr.equalsIgnoreCase(it.routeBase.toStr) && route.httpMethod == it.httpMethod }
//			if (dup != null)
//				throw BedSheetErr(BsMsgs.routeAlreadyAdded(dup.routeBase, dup.handler))
			dups.add(route)
		}

		innies := Route[,]
		dups.each |route| {
//			innies.each {
//				if (route.routeBase != it.routeBase) {
//					if (route.routeBase.toStr.startsWith(it.routeBase.toStr))
//						throw BedSheetErr(BsMsgs.routesCanNotBeNested(route.routeBase, it.routeBase))
//					if (it.routeBase.toStr.startsWith(route.routeBase.toStr))
//						throw BedSheetErr(BsMsgs.routesCanNotBeNested(it.routeBase, route.routeBase))
//				}
//			}
			innies.add(route)
		}
		
		this.routes = innies
		
		// validate welcome page uri
		if (welcomePage != null)
			verify := Route(welcomePage, #toStr)
	}

	** Match a request uri to Route.
	internal Obj match(Uri modRel, Str httpMethod) {
		normalisedUri := normalise(modRel)
		
		return routes.eachWhile |route| {
			
			routeMatch := route.match(normalisedUri, httpMethod) 
			if (routeMatch == null) {
				return null
			}
			
			// save the routeMatch so it can be picked up by `Request` for routeBase() & routeMod()
			webReq.stash["bedSheet.routeMatch"] = routeMatch

			result := routeHandler.handle(routeMatch)
			
			return (result == false) ? null : result 
			
		} ?: throw RouteNotFoundErr(BsMsgs.routeNotFound(modRel))
		
		// TODO: if req uri is '/' and no routes have been defined, route to a default 'BedSheet Welcome' page
		// TODO: have this as a contributed route, after *! Use config to turn on and off
	}
	
	private Uri normalise(Uri uri) {
		if (uri.path.isEmpty) {
			if (welcomePage == null)
				throw RouteNotFoundErr(BsMsgs.routeNotFound(uri))
			uri = welcomePage
		}
		if (!uri.isPathAbs)
			uri = `/` + uri
		return uri
	}
	
	private WebReq webReq() {
		registry.dependencyByType(WebReq#)
	}	
}

internal const class RouteMatch {
	const Uri 		routeBase
	const Uri		routeRel
	const Str 		httpMethod
	const Method	handler
	
	new make(Uri routeBase, Uri routeRel, Str httpMethod, Method handler) {
		this.routeBase	= routeBase
		this.routeRel	= routeRel
		this.httpMethod = httpMethod
		this.handler	= handler
	}
	
	Str[] argList() {
		routePath	:= routeRel.path
		if (handler.params.size == routePath.size)
			return routePath
		
		paramRange	:= (handler.params.findAll { !it.hasDefault }.size..<handler.params.size)
		if (paramRange.contains(routePath.size))
			return routePath

		throw RouteNotFoundErr(BsMsgs.handlerArgSizeMismatch(handler, routeRel))
	}
}
