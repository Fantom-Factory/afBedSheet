using afIoc::ConcurrentState
using afIoc::Inject
using afIoc::Registry
using afIoc::ServiceStats
using afIoc::ServiceStat

internal const class MethodCallResponseProcessor : ResponseProcessor {
	private const static Log 		log 		:= Utils.getLog(MethodCallResponseProcessor#)
	private const ConcurrentState 	conState	:= ConcurrentState(MethodCallResponseProcessorState#)
	private const [Str:ServiceStat] serviceStats
	
	@Inject	private const Registry 		registry
	@Inject	private const ValueEncoders valueEncoders	

	new make(ServiceStats serviceStats, |This|in) {
		in(this) 
		
		// we can cache the stats 'cos we only care about the service types
		this.serviceStats = serviceStats.stats
	}
	
	override Obj process(Obj response) {
		methodCall := (MethodCall) response
		
		handlerType := methodCall.method.parent

		handler := getState |state->Obj| {

			if (state.isService(handlerType))
				return "iocService"

			if (state.isAutobuild(handlerType))
				return "autobuild"

			if (state.isCached(handlerType))
				return state.handlerCache[handlerType]

			// TODO: we may want to change this to 'handlerType.fits(it.type)' should our ModuleImpl change 
			if (serviceStats.any { handlerType == it.type }) {
				state.serviceTypes.add(handlerType)
				return "iocService"
			}
			
			if (handlerType.isConst) {
				state.handlerCache[handlerType] = registry.autobuild(handlerType)
				return state.handlerCache[handlerType]
			}

			state.autobuildTypes.add(handlerType)
			return "autobuild"
		}
		
		if (handler.typeof == Str#) {
			if (handler == "iocService")
				// need to get outside of getState() 'cos handler may not be const 
				handler = registry.dependencyByType(handlerType)
			
			if (handler == "autobuild")
				// need to build outside of getState() 'cos handler may not be const 
				handler = registry.autobuild(handlerType)
		}

		args := convertArgs(methodCall.method, methodCall.args)
		
		result := methodCall.method.callOn(handler, args)

		return (result == null) ? false : result
	}

	** Convert the Str from Routes into real arg objs
	private Obj[] convertArgs(Method method, Obj?[] argsIn) {
		// FIXME:test when we have more args than method parama!
		argsOut := argsIn.map |arg, i -> Obj?| {
			paramType	:= method.params[i].type
			decode 		:= arg != null && arg.typeof.fits(Str#)
			value		:= decode ? valueEncoders.toValue(paramType, arg) : arg
			return value
		}
		return argsOut
	}
	
	private Void withState(|MethodCallResponseProcessorState| state) {
		conState.withState(state)
	}

	private Obj? getState(|MethodCallResponseProcessorState -> Obj| state) {
		conState.getState(state)
	}
}

internal class MethodCallResponseProcessorState {
	Type[]		serviceTypes	:= [,]
	Type[]		autobuildTypes	:= [,]
	Type:Obj	handlerCache	:= [:]

	Bool isService(Type handlerType) {
		serviceTypes.contains(handlerType)
	}

	Bool isAutobuild(Type handlerType) {
		autobuildTypes.contains(handlerType)
	}

	Bool isCached(Type handlerType) {
		handlerCache.containsKey(handlerType)
	}
}