using afIoc::StrategyRegistry

** @Inject - Holds a collection of `ResponseProcessor`s.
const mixin ResponseProcessors {

	@NoDoc
	abstract Void processResponse(Obj response)

}

internal const class ResponseProcessorsImpl : ResponseProcessors {

	private const StrategyRegistry processorStrategy

	internal new make(Type:ResponseProcessor responseProcessors) {
		processorStrategy = StrategyRegistry(responseProcessors)
	}

	override Void processResponse(Obj response) {
		while (response != true)
			response = get(response.typeof).process(response)
	}	

	private ResponseProcessor get(Type responseType) {
		processorStrategy.findBestFit(responseType)
	}
}
