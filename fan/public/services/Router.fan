using web

**
** Router handles routing URIs to method handlers.
**
const class Router {
	const Route[] routes

	new make(Route[] routes) { 
		this.routes = routes
	}

	** Match a request to Route. If no matches are found, returns
	** 'null'.	The first route that matches is chosen.	Routes
	internal RouteMatch? match(Uri uri, Str method) {
		for (i:=0; i<routes.size; i++) {
			r := routes[i]
			m := r.match(uri, method)
			if (m != null) return RouteMatch(r, m)
		}
		return null
	}
}

**
** RouteMatch models a matched Route instance.
**
internal const class RouteMatch {

	** Matched route instance.
	const Route route

	** Arguments for matched Route.
	const Str:Str args
	
	new make(Route route, Str:Str args) {
		this.route = route
		this.args	= args
	}

}


