
** Calls the given method with arg from the Route match.
internal const class RouteMethod {
	const Method method
	
	new make(Method method) {
		this.method = method
	}
	
	override Str toStr() { method.toStr }
}
