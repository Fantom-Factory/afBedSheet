using web

**
** Router handles routing URIs to method handlers.
**
// TODO: maybe abstract this away so routing becomes pluggable
const class Router {
	const Route[] routes

	new make(Route[] routes) {
		dups := Route[,]
		routes.each |route| {
			dup	:= dups.find { route.routeBase.toStr.equalsIgnoreCase(it.routeBase.toStr) && route.httpMethod == it.httpMethod }
			if (dup != null)
				throw BedSheetErr(BsMsgs.routeAlreadyAdded(dup.routeBase, dup.handler))
			dups.add(route)
		}

		innies := Route[,]
		dups.each |route| {
			innies.each {
				if (route.routeBase != it.routeBase) {
					if (route.routeBase.toStr.startsWith(it.routeBase.toStr))
						throw BedSheetErr(BsMsgs.routesCanNotBeNested(route.routeBase, it.routeBase))
					if (it.routeBase.toStr.startsWith(route.routeBase.toStr))
						throw BedSheetErr(BsMsgs.routesCanNotBeNested(it.routeBase, route.routeBase))
				}
			}
			innies.add(route)
		}
		
		this.routes = innies
	}

	** Match a request uri to Route.
	internal RouteMatch match(Uri modRel, Str httpMethod) {
		routes.eachWhile{ it.match(normalise(modRel), httpMethod) } 
			?: throw RouteNotFoundErr(BsMsgs.routeNotFound(modRel))
	}
	
	private Uri normalise(Uri uri) {
		if (uri == ``)
			uri = `index`	// TODO: config welcome page
		if (!uri.isPathAbs)
			uri = `/` + uri
		return uri
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
