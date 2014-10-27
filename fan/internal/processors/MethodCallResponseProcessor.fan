using afIoc
using afConcurrent

internal const class MethodCallResponseProcessor : ResponseProcessor {
	private const static Log 	log 				:= Utils.getLog(MethodCallResponseProcessor#)
	private const Type[] 		serviceTypeCache
	private const AtomicMap		constTypeCache		:= AtomicMap()
	private const AtomicList	autobuildTypeCache	:= AtomicList()
	
	@Inject	private const Registry 		registry
	@Inject	private const ValueEncoders valueEncoders	

	new make(|This|in) {
		in(this) 
		
		// we can cache the stats 'cos we only care about the service types
		this.serviceTypeCache = registry.serviceDefinitions.vals.map { it.serviceType }
	}

	override Obj process(Obj response) {
		methodCall := (MethodCall) response
		
		handler := null
		if (!methodCall.method.isStatic) {
			handlerType := methodCall.method.parent
			if (serviceTypeCache.contains(handlerType))
				handler = registry.dependencyByType(handlerType)
	
			if (constTypeCache.containsKey(handlerType))
				handler = constTypeCache[handlerType]
			
			if (autobuildTypeCache.contains(handlerType))
				handler = registry.autobuild(handlerType)
			
			if (handler == null) {
				if (handlerType.isConst) {
					handler = registry.autobuild(handlerType)
					constTypeCache.set(handlerType, handler)
					
				} else {
					autobuildTypeCache.add(handlerType)
					handler = registry.autobuild(handlerType)
				}
			}
		}

		args 	:= convertArgs(methodCall.method, methodCall.args)
		
		// the standard method call
//		result	:= methodCall.method.callOn(handler, args)

		// use afIoc to call the method, injecting in any extra params
		// This may seem pointless for routes (which need to match all params on the uri) but it *may* prove useful for
		// other uses of MethodCalls. The Jury's out; I may remove this feature if it proves too bloated and under used.
		result	:= registry.callMethod(methodCall.method, handler, args) 

		return (result == null) ? false : result
	}

	** Convert the Str from Routes into real arg objs
	private Obj?[] convertArgs(Method method, Obj?[] argsIn) {
		try
			return argsIn.map |arg, i -> Obj?| {
				// guard against having more args than the method has params! 
				// Should never happen if the Routes do their job!
				paramType	:= method.params.getSafe(i)?.type
				if (paramType == null)
					return arg
				return arg is Str ? valueEncoders.toValue(paramType, arg) : arg
			}
		// if the args can't be converted then clearly the URL doesn't exist!
		catch (ValueEncodingErr valEncErr) {
			throw HttpStatusErr(404, valEncErr.msg, valEncErr)
		}
	}	
}
