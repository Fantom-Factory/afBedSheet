using afIoc::Inject

internal const class RouteMatcherArgImpl : RouteMatcher {
	
	@Inject
	private const ValueEncoderSource valueEncoderSource
	
	new make(|This|in) { in(this) }
	
	override RouteMatch? match(Obj objRoute, Uri uri, Str httpMethod) {
		argRoute := (ArgRoute) objRoute
		
		routeRel	:= argRoute.match(uri, httpMethod)
		if (routeRel == null)
			return null
		
		// param special cases
		Obj[]? args	:= null
		if (argRoute.handler.params.size == 1) {
			paramType := argRoute.handler.params[0].type
			if (paramType.fits(Uri#))
				args = [routeRel]
			
			if (paramType.fits(Str#.toListOf))
				args = [routeRel.path]
		}
		
		// watch out for ->Obj nulls here if ValEnc sig changes
		args = args ?: argRoute.argList(routeRel).map |arg, i -> Obj| {
			paramType	:= argRoute.handler.params[i].type
			value		:= valueEncoderSource.toValue(paramType, arg)
			return value
		}
				
		return RouteMatch(argRoute.routeBase, routeRel, argRoute.handler, args)
	}
}
