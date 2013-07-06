using afIoc::StrategyRegistry

** Holds a collection of `HandlerResponseProcessor`s.
const class ResponseProcessorSource {

	private const StrategyRegistry processorStrategy

	new make(Type:ResponseProcessor responseProcessors) {
		processorStrategy = StrategyRegistry(responseProcessors)
	}

	internal Void processResponse(Obj response) {
		get(response.typeof).process(response)
	}	
	
	private ResponseProcessor get(Type responseType) {
		processorStrategy.findBestFit(responseType)
	}	
}
