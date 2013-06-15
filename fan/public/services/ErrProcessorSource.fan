using afIoc::StrategyRegistry

** Holds a collection of `ErrProcessor`s.
const class ErrProcessorSource {
	
	private const StrategyRegistry errProcessorStrategy
	
	new make(Type:ErrProcessor errProcessors) {
		this.errProcessorStrategy = StrategyRegistry(errProcessors)
	}
	
	internal Obj process(Err err) {
		get(err).process(err)
	}

	internal ErrProcessor get(Err err) {
		// TODO: search the causes for an exact match first
		errProcessorStrategy.findBestFit(err.typeof)
	}
	
}
