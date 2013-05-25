
const class ResultProcessorSource {
	
	private const Type:ResultProcessor resultProcessors
	
	new make(Type:ResultProcessor resultProcessors) {
		this.resultProcessors = resultProcessors
	}
	
	// TODO: use cached adaprter pattern - see ModuleImpl.serviceDefsByType
	internal ResultProcessor getResultProcessor(Type resultType) {
		resultProcessors.find |processor, type| {
			resultType.fits(type)
        }
		// TODO: throw better Err if not found
	}
	
}
