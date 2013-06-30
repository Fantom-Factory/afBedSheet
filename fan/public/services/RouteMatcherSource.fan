using afIoc::StrategyRegistry

** Holds a strategy of routing types to their handlers.
** 
** @uses MappedConfig of 'Type:RouteMatcher' where 'Type' is what's contributed to 'Routes' 
const class RouteMatcherSource {

	private const StrategyRegistry routeMatcherStrategy

	new make(Type:RouteMatcher routeMatchers) {
		routeMatcherStrategy = StrategyRegistry(routeMatchers)
	}

	internal RouteMatcher get(Type routeType) {
		routeMatcherStrategy.findExactMatch(routeType)
	}
}
