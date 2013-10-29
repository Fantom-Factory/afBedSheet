
// FIXME: rename to RouteMatch / MethodInvoker?
** Return from 'RouteMatchers'.
class RouteHandler {
	const Method	method
		  Obj?[]	args
	
	new make(Method method, Obj?[] args) {
		this.method	= method
		this.args	= args
	}
	
	Obj? invokeOn(Obj handlerInst) {
		handlerInst.trap(method.name, args)
	}

	
}