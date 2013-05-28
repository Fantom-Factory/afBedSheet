using afIoc::StrategyRegistry

** Holds a collection of `HandlerResultProcessor`s.
const class ResultProcessorSource {

	private const StrategyRegistry processorStrategy

	new make(Type:ResultProcessor resultProcessors) {
		processorStrategy = StrategyRegistry(resultProcessors)
	}

	internal Void process(Obj result) {
		get(result.typeof).process(result)
	}	
	
	
	internal ResultProcessor get(Type resultType) {
		processorStrategy.findBestFit(resultType)
	}	
}
