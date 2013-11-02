
** Return from 'RouteMatchers'.
class MethodInvoker {
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