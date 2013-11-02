
** A 'RouteMatcher' checks to see if a given Route Obj matches a request. It should return a 
** 'MethodInvoker' if successful and 'null' if not. 
** 
** 'RouteMatchers' must be contributed to `RouteMatcherSource`. A 'RouteMatcher' will only be 
** called with Routes it has been registered with. 
mixin RouteMatcher {
	
	** Match this route (optionally) against the given request arguments. 
	** Return 'null' if no match.
	abstract MethodInvoker? match(Obj route, Uri uri, Str httpMethod)
	
}
