using afIoc::StrategyRegistry

** @Inject - Holds a collection of `ErrProcessor`s.
** 
** pre>
**   @Contribute { serviceType=ErrProcessors# }
**   static Void contributeErrProcessors(MappedConfig conf) {
**     conf[Err#] = CatchAllErrHandler()
**   }
** <pre
** 
** @uses a MappedConfig of 'Type:ErrProcessor' where 'Type' is a subclass of 'Err' or a mixin.
const mixin ErrProcessors {
	
	@NoDoc
	abstract Obj processErr(Err err)
}

internal const class ErrProcessorsImpl : ErrProcessors {

	private const StrategyRegistry errProcessorStrategy
	
	internal new make(Type:ErrProcessor errProcessors) {
		errProcessors.keys.each |type| {
			if (type.isClass && !type.fits(Err#))
				throw BedSheetErr(BsErrMsgs.errProcessorsNotErrType(type))
		}
		this.errProcessorStrategy = StrategyRegistry(errProcessors)
	}
	
	override Obj processErr(Err err) {
		get(err.typeof).process(err)
	}

	private ErrProcessor get(Type errType) {
		return errProcessorStrategy.findBestFit(errType)
	}
}
