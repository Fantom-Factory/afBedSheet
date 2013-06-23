using afIoc::StrategyRegistry

const class RouteMatcherSource {

	private const StrategyRegistry routeMatcherStrategy

	new make(Type:RouteMatcher routeMatchers) {
		routeMatcherStrategy = StrategyRegistry(routeMatchers)
	}

	internal RouteMatcher get(Type routeType) {
		routeMatcherStrategy.findExactMatch(routeType)
	}
}
