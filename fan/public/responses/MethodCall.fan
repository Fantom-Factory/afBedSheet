
** (Response Object) Use to explicitly invoke Fantom methods. 
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
	
	** Returns an immutable func that represents this method call. May be used as response object itself.
	** 'instance' may be null id 
	** 
	** TODO: Suggest design ideas for [implementing Obj.toImmutable()]`http://fantom.org/forum/topic/2263`
	virtual Func immutable() {
		iMeth := this.method
		iArgs := this.args.toImmutable
		return |ObjCache objCache -> Obj?| {
			if (iMeth.isStatic)
				return iMeth.callList(iArgs)
			handler := objCache[iMeth.parent]
			return iMeth.callOn(handler, iArgs)
		}.toImmutable
	}
	
	@NoDoc
	override Str toStr() {
		method.signature
	}
}
