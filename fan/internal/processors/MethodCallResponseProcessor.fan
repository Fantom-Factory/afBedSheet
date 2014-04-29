using afIoc
using afConcurrent

internal const class MethodCallResponseProcessor : ResponseProcessor {
	private const static Log 	log 				:= Utils.getLog(MethodCallResponseProcessor#)
	private const AtomicList	serviceTypeCache	:= AtomicList()
	private const AtomicList	autobuildTypeCache	:= AtomicList()
	private const AtomicMap		handlerTypeCache	:= AtomicMap()
	private const Type[] 		serviceTypes
	
	@Inject	private const Registry 		registry
	@Inject	private const ValueEncoders valueEncoders	

	new make(ServiceStats serviceStats, |This|in) {
		in(this) 
		
		// we can cache the stats 'cos we only care about the service types
		this.serviceTypes = serviceStats.stats.vals.map { it.serviceType }
	}

	override Obj process(Obj response) {
		methodCall := (MethodCall) response
		
		handlerType := methodCall.method.parent

		handler := null
		
		if (serviceTypeCache.contains(handlerType))
			handler = registry.dependencyByType(handlerType)

		if (handlerTypeCache.containsKey(handlerType))
			handler = handlerTypeCache[handlerType]
		
		if (autobuildTypeCache.contains(handlerType))
			handler = registry.autobuild(handlerType)
		
		if (handler == null) {
			if (serviceTypes.any { handlerType.fits(it) }) {
				serviceTypeCache.add(handlerType)
				handler = registry.dependencyByType(handlerType)
			} else
			
			if (handlerType.isConst) {
				handler = registry.autobuild(handlerType)
				handlerTypeCache.set(handlerType, handler)
			} else
			
			{
				autobuildTypeCache.add(handlerType)
				handler = registry.autobuild(handlerType)
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
	private Obj[] convertArgs(Method method, Obj?[] argsIn) {
		argsOut := argsIn.map |arg, i -> Obj?| {
			// guard against having more args than the method has params! 
			// Should never happen if the Routes do their job!
			paramType	:= method.params.getSafe(i)?.type
			if (paramType == null)
				return arg
			decode 		:= arg != null && arg.typeof.fits(Str#)
			value		:= decode ? valueEncoders.toValue(paramType, arg) : arg
			return value
		}
		return argsOut
	}	
}
