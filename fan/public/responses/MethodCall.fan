
** TODO: put in fandoc
class MethodCall {
	const Method	method
		  Obj?[]	args
	
	new make(Method method, Obj?[] args) {
		this.method	= method
		this.args	= args
	}
}
