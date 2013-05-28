using afIoc::StrategyRegistry

** Holds a collection of `ErrProcessor`s.
const class ErrProcessorSource {
	
	private const StrategyRegistry errProcessorStrategy
	
	new make(Type:ErrProcessor errProcessors) {
		this.errProcessorStrategy = StrategyRegistry(errProcessors)
	}
	
	internal ErrProcessor getErrProcessor(Err err) {
		// TODO: search the causes for an exact match first
		errProcessorStrategy.findBestFit(err.typeof)
	}
	
}
