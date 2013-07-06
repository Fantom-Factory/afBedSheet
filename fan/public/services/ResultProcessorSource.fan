using afIoc::StrategyRegistry

** Holds a collection of `HandlerResultProcessor`s.
const class ResultProcessorSource {

	private const StrategyRegistry processorStrategy

	new make(Type:ResultProcessor resultProcessors) {
		processorStrategy = StrategyRegistry(resultProcessors)
	}

	internal Void processResponse(Obj response) {
		get(response.typeof).process(response)
	}	
	
	private ResultProcessor get(Type resultType) {
		processorStrategy.findBestFit(resultType)
	}	
}
