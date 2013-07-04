
class RouteMatch {
	@Deprecated
	const Uri 		routeBase
	@Deprecated
	const Uri		routeRel
	const Method	handler
		  Obj[]		args
	
	new make(Uri routeBase, Uri routeRel, Method handler, Obj[] args) {
		this.routeBase	= routeBase
		this.routeRel	= routeRel
		this.handler	= handler
		this.args		= args
	}
	
	Obj? invokeHandler(Obj handlerInst) {
		handlerInst.trap(handler.name, args)
	}
}