using afIoc::Inject

internal const class RouteMatcherImpl : RouteMatcher {
	
	@Inject
	private const ValueEncoders valueEncoders
	
	new make(|This|in) { in(this) }
	
	override RouteHandler? match(Obj objRoute, Uri uri, Str httpMethod) {
		route := (Route) objRoute
		
		params	:= route.match(uri, httpMethod)
		if (params == null)
			return null
		
		// watch out for ->Obj nulls here if ValEnc sig changes
		args := params.map |arg, i -> Obj| {
			paramType	:= route.handler.params[i].type
			value		:= valueEncoders.toValue(paramType, arg)
			return value
		}

		return RouteHandler(route.handler, args)
	}
}
