
class RouteMatch {
	const Uri 		routeBase
	const Uri		routeRel
	const Method	handler
		  Obj[]		args
	
	new make(Uri routeBase, Uri routeRel, Method handler, Obj[] args) {
		this.routeBase	= routeBase
		this.routeRel	= routeRel
		this.handler	= handler
		this.args		= args
	}
}