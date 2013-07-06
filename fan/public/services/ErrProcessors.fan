using afIoc::StrategyRegistry

** Holds a collection of `ErrProcessor`s.
const class ErrProcessors {
	
	private const StrategyRegistry errProcessorStrategy
	
	internal new make(Type:ErrProcessor errProcessors) {
		this.errProcessorStrategy = StrategyRegistry(errProcessors)
	}
	
	internal Obj processErr(Err err) {
		get(err.typeof).process(err)
	}

	internal ErrProcessor get(Type errType) {
		// TODO: search the causes for an exact match first
		errProcessorStrategy.findBestFit(errType)
	}
	
}
