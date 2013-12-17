
** Return from request handler methods to explicitly invoke class methods. 
** 
** If the method belongs to an 'afIoc' service, the class instance is obtained from afIoc. 
** If the method belongs to a 'const' class, a new instance is created and cached. 
** Non-const classes are cached for the duration of the request only.    
**   
class MethodCall {
	const Method	method
		  Obj?[]	args
	
	new make(Method method, Obj?[] args := Obj#.emptyList) {
		this.method	= method
		this.args	= args
	}
}
