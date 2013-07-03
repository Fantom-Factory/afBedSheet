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
		
		// TODO: look for special cases at the end of the arg list (in the loop), like splats
		// param special cases
		Obj[]? args	:= null
		if (argRoute.handler.params.size == 1) {
			paramType := argRoute.handler.params[0].type
			if (paramType.fits(Uri#))
				args = [routeRel]
			
			if (paramType.fits(Str#.toListOf))
				args = [routeRel.path]
		}
		
		if (args == null) {
			// watch out for ->Obj nulls here if ValEnc sig changes
			args = argRoute.argList(routeRel)
			
			if (args == null)
				return null

			args = args.map |arg, i -> Obj| {
				paramType	:= argRoute.handler.params[i].type
				value		:= valueEncoderSource.toValue(paramType, arg)
				return value
			}
		}
				
		return RouteMatch(argRoute.routeBase, routeRel, argRoute.handler, args)
	}
}
