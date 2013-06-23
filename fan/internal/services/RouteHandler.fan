using afIoc::ConcurrentState
using afIoc::Inject
using afIoc::Registry
using afIoc::ServiceStats

internal const class RouteHandler {
	private const static Log 		log 		:= Utils.getLog(BedSheetService#)
	private const ConcurrentState 	conState	:= ConcurrentState(RouteHandlerState#)

	@Inject
	private const Registry registry

	@Inject
	private const ValueEncoderSource valueEncoderSource
	
	new make(|This|in) { in(this) }
	
	Obj handle(RouteMatch routeMatch) {
		
		handlerType := routeMatch.handler.parent
		// TODO: isConst - we should also check for threaded services - for reuse
		handlerInst	:= handlerType.isConst 
			? getState |state->Obj| {
				state.handlerCache.getOrAdd(handlerType) |->Obj| {
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
		
		result := handlerInst.trap(routeMatch.handler.name, routeMatch.args)
		
		if (result == null) {
			if (routeMatch.handler.returns == Void#)
				log.warn(BsMsgs.handlersCanNotBeVoid(routeMatch.handler))
			else
				log.err(BsMsgs.handlersCanNotReturnNull(routeMatch.handler))
			result = false
		}
		
		return result
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