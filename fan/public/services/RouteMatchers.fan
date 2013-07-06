using afIoc::StrategyRegistry

** Holds a strategy of routing types to their handlers.
** 
** @uses MappedConfig of 'Type:RouteMatcher' where 'Type' is what's contributed to 'Routes' 
const class RouteMatchers {

	private const StrategyRegistry routeMatcherStrategy

	internal new make(Type:RouteMatcher routeMatchers) {
		routeMatcherStrategy = StrategyRegistry(routeMatchers)
	}

	internal RouteMatch? matchRoute(Obj route, Uri uri, Str httpMethod) {
		get(route.typeof).match(route, uri, httpMethod)
	}
	
	private RouteMatcher get(Type routeType) {
		routeMatcherStrategy.findBestFit(routeType)
	}	
}
