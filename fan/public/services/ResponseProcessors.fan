using afIoc::StrategyRegistry

** (Service) - Contribute your `ResponseProcessor` implementations to this.
** 
** @uses a MappedConfig of 'Type:ResponseProcessor'
@NoDoc	// don't overwhelm the masses!
const mixin ResponseProcessors {

	** Recursively processes the response object until 'true' or 'false' is returned
	@NoDoc // not for public use
	abstract Bool processResponse(Obj response)

}

internal const class ResponseProcessorsImpl : ResponseProcessors {

	private const StrategyRegistry processorStrategy

	internal new make(Type:ResponseProcessor responseProcessors) {
		processorStrategy = StrategyRegistry(responseProcessors)
	}

	override Bool processResponse(Obj response) {
		while (!response.typeof.fits(Bool#)) {
			try {
				response = get(response.typeof).process(response)
				
			// We handle ReProcessErrs as close to the source as possible as not to bounce back through any 
			// Middleware
			} catch (ReProcessErr rpe) {
				// re-process any, um, ReProcessErrs!
				response = rpe.responseObj
			}
		}
		
		// false is fine, it means it wasn't handled, fall through to the next route / middleware
		return response
	}	

	private ResponseProcessor get(Type responseType) {
		processorStrategy.findClosestParent(responseType)
	}
}
