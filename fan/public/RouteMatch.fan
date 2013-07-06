
** Returned from 'RouteMatchers'.
class RouteMatch {
	const Method	handler
		  Obj[]		args
	
	new make(Method handler, Obj[] args) {
		this.handler	= handler
		this.args		= args
	}
	
	Obj? invokeHandler(Obj handlerInst) {
		handlerInst.trap(handler.name, args)
	}
}