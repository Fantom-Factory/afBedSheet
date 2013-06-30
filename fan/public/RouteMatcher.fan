
** A 'RouteMatcher' checks to see if a given Route Obj matches a request. It returns a 'RouteMatch' 
** if successful and 'null' if not. 
** 
** All 'RouteMatchers' must be contributed to `RouteMatcherSource`. 
mixin RouteMatcher {
	
	** Match this route against the request arguments. 
	** Return 'null' if no match.
	abstract RouteMatch? match(Obj route, Uri uri, Str httpMethod)
	
}
