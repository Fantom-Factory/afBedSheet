using afIoc::ConcurrentState
using afIoc::Inject
using afIoc::Registry
using afIoc::ServiceStats

internal const class RouteHandler {
	private const ConcurrentState 	conState	:= ConcurrentState(RouteHandlerState#)

	@Inject
	private const Registry registry

	@Inject
	private const ValueEncoderSource valueEncoderSource
	
	new make(|This|in) { in(this) }
	
	Obj? handle(RouteMatch routeMatch) {
		
		handlerType := routeMatch.handler.parent
		handlerInst	:= handlerType.isConst 
			? getState |state->Obj| {
				state.handlerCache.getOrAdd(handlerType) |->Obj| {
					// TODO: we should also check for threaded services
					// maybe put checked=true on reg.dependencyByType and reg.serviceById ??
					serviceStats 	:= (ServiceStats) registry.dependencyByType(ServiceStats#)
					serviceStat		:= serviceStats.stats.find { it.type == handlerType }
					service			:= (serviceStat == null) 
									? registry.autobuild(handlerType)
									: registry.serviceById(serviceStat.serviceId)
					return service
				}
			}
			// no need to stash in Thread, 'cos currently there's only 1 handler per req
			: registry.autobuild(handlerType)

		// param special cases
		Obj[]? args	:= null
		if (routeMatch.handler.params.size == 1) {
			paramType := routeMatch.handler.params[0].type
			if (paramType.fits(Uri#))
				args = [routeMatch.routeRel]
			
			if (paramType.fits(Str#.toListOf))
				args = routeMatch.routeRel.path
		}
		
		// watch out for ->Obj nulls here if ValEnc sig changes
		args = args ?: routeMatch.argList.map |arg, i -> Obj| {
			paramType	:= routeMatch.handler.params[i].type
			valEnc		:= valueEncoderSource.getValueEncoder(paramType)
			value		:= valEnc.toValue(arg)
			return value
		}
		
		return handlerInst.trap(routeMatch.handler.name, args)
	}
	
	private Void withState(|RouteHandlerState| state) {
		conState.withState(state)
	}

	private Obj? getState(|RouteHandlerState -> Obj| state) {
		conState.getState(state)
	}
}

internal class RouteHandlerState {
	Type:Obj	handlerCache	:= [:]
}