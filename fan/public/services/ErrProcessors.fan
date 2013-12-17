using afIoc::Inject
using afIoc::StrategyRegistry

** (Service) - Contribute your 'ErrProcessor' implementations to this. 
** Example, in your 'AppModule':
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

	** Returns the result of processing the given 'Err'.
	@NoDoc	// not intended for public use
	abstract Obj processErr(Err err)
}

internal const class ErrProcessorsImpl : ErrProcessors {

	private const StrategyRegistry errProcessorStrategy

	@Inject @Config { id="afBedSheet.errProcessors.default" }
	private const ErrProcessor defaultErrProcessor
	
	
	internal new make(Type:ErrProcessor errProcessors, |This|in) {
		in(this)
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
		errProcessorStrategy.findBestFit(errType, false) ?: defaultErrProcessor
	}
}
