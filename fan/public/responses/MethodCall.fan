
** (Response Object) - 
** Use to explicitly invoke Fantom methods. 
** 
**   syntax: fantom
**   MethodCall(MyHandler#process, ["arg1", "arg2"]).toImmutableFunc
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
	
	** Returns an immutable func that represents this method call. 
	** May be used as a response object itself.
	** 
	** If this 'MethodCall' wraps an instance method (not static) then the returned func's first (and only) 
	** argument must be the target object. Otherwise the func takes no arguments.
	** 
	** TODO: Suggest design ideas for [implementing Obj.toImmutable()]`http://fantom.org/forum/topic/2263`
	virtual Func toImmutableFunc() {
		iMeth := this.method
		iArgs := this.args.toImmutable
		if (iMeth.isStatic)
			return |->Obj?| {
				iMeth.callList(iArgs)
			}
		
		func := |Obj target -> Obj?| {
			iMeth.callOn(target, iArgs)
		}.toImmutable	// needed else the retype isn't immutatble
		
		// this is some hardcore reflective shit going down here!
		targetType := iMeth.parent
		funcType := Func#.parameterize(["A":targetType, "R":Obj?#])
		return func.retype(funcType).toImmutable
	}
	
	@NoDoc
	override Str toStr() {
		method.signature
	}	
}
