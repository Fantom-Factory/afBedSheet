
** Return from request handler methods to explicitly invoke Fantom methods. 
** 
** Note that:
**  - if the method belongs to an 'IoC' service, the class instance is obtained from afIoc. 
**  - if the method belongs to a 'const' class, a new instance is created and cached. 
**  - non-const classes are cached for the duration of the request only.    
**  - methods are called using 'afIoc::Registry.callMethod(...)' so may have services as parameters. 
class MethodCall {
	
	** The method to be called 
	const Method	method
	
	** The arguments the method is to be called with 
		  Obj?[]	args
	
	** Creates a 'MethodCall'.
	new make(Method method, Obj?[] args := Obj#.emptyList) {
		this.method	= method
		this.args	= args
	}
	
	@NoDoc
	override Str toStr() {
		method.signature
	}
}
