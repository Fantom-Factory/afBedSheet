using afIoc::ConcurrentState
using afIoc::Inject
using afIoc::Registry
using afIoc::ServiceStats
using afIoc::ServiceStat

internal const class ReqestHandlerInvoker {
	private const static Log 		log 		:= Utils.getLog(ReqestHandlerInvoker#)
	private const ConcurrentState 	conState	:= ConcurrentState(RouteHandlerState#)
	private const [Str:ServiceStat] serviceStats
	
	@Inject
	private const Registry registry

	new make(ServiceStats serviceStats, |This|in) {
		in(this) 
		
		// we can cache the stats 'cos we only care about the service types
		this.serviceStats = serviceStats.stats
	}
	
	Obj? invokeHandler(RouteMatch routeMatch) {
		handlerType := routeMatch.handler.parent

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

		return routeMatch.invokeHandler(handler)
	}
	
	private Void withState(|RouteHandlerState| state) {
		conState.withState(state)
	}

	private Obj? getState(|RouteHandlerState -> Obj| state) {
		conState.getState(state)
	}
}

internal class RouteHandlerState {
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