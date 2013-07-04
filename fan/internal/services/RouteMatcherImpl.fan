using afIoc::Inject

internal const class RouteMatcherImpl : RouteMatcher {
	
	@Inject
	private const ValueEncoderSource valueEncoderSource
	
	new make(|This|in) { in(this) }
	
	override RouteMatch? match(Obj objRoute, Uri uri, Str httpMethod) {
		route := (Route) objRoute
		
		params	:= route.match(uri, httpMethod)
		if (params == null)
			return null
		
		// TODO: look for special cases at the end of the arg list (in the loop), like splats
		// param special cases
		// FIXME: test
		Obj[]? args	:= null
		if (route.handler.params.size == 1) {
			paramType := route.handler.params[0].type
//			if (paramType.fits(Uri#))
//				args = [routeRel]
//			
			if (paramType.fits(Str#.toListOf))
				args = params
		}
		
		if (args == null) {
			// watch out for ->Obj nulls here if ValEnc sig changes
			args = params.map |arg, i -> Obj| {
				paramType	:= route.handler.params[i].type
				value		:= valueEncoderSource.toValue(paramType, arg)
				return value
			}
		}

		return RouteMatch(route.handler, args)
	}
}
