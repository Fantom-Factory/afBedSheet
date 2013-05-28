using afIoc::StrategyRegistry

const class ResultProcessorSource {

	private const StrategyRegistry resultProcessorStrategy

	new make(Type:HandlerResultProcessor resultProcessors) {
		resultProcessorStrategy = StrategyRegistry(resultProcessors)
	}

	internal HandlerResultProcessor getHandlerResultProcessor(Type resultType) {
		resultProcessorStrategy.findBestFit(resultType)
	}	
}
