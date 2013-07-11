using afIoc::StrategyRegistry

** Holds a collection of `ErrProcessor`s.
const class ErrProcessors {
	
	private const StrategyRegistry errProcessorStrategy
	
	internal new make(Type:ErrProcessor errProcessors) {
		this.errProcessorStrategy = StrategyRegistry(errProcessors)
	}
	
	internal Obj processErr(Err err) {
		// TODO: search the causes for an exact match first
		
//		causes(err).eachWhile |cause| {
//			
//		}

		return get(err.typeof).process(err)
	}

	internal ErrProcessor get(Type errType) {
		
		return errProcessorStrategy.findBestFit(errType)
	}
	
	private Err[] causes(Err err, Err[] errs:= [,]) {
		errs.insert(0, err)
		return (err.cause != null) ? causes(err.cause, errs) : errs
	}
	
}
