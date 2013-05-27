using afIoc::StrategyRegistry

const class ResultProcessorSource {

	private const StrategyRegistry resultProcessorStrategy

	new make(Type:ResultProcessor resultProcessors) {
		resultProcessorStrategy = StrategyRegistry(resultProcessors)
	}

	internal ResultProcessor getResultProcessor(Type resultType) {
		resultProcessorStrategy.findBestFit(resultType)
	}	
}
