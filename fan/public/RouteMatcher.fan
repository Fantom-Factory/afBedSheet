
mixin RouteMatcher {
	
	** Match this route against the request arguments. 
	** Return 'null' if no match.
	abstract RouteMatch? match(Obj route, Uri uri, Str httpMethod)
	
}
