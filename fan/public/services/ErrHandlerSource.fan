using afIoc::StrategyRegistry

const class ErrHandlerSource {
	
	private const StrategyRegistry errHandlerStrategy
	
	new make(Type:ErrHandler errHandlers) {
		this.errHandlerStrategy = StrategyRegistry(errHandlers)
	}
	
	internal ErrHandler getErrHandler(Err err) {
		// TODO: search the causes for an exact match first
		errHandlerStrategy.findBestFit(err.typeof)
	}
	
}
