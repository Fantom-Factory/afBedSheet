using afIoc::StrategyRegistry

** Holds a collection of `ErrProcessor`s.
** 
** pre>
**   @Contribute { serviceType=HttpStatusProcessors# }
**   static Void contributeHttpStatusProcessors(MappedConfig conf) {
**     conf[404] = conf.autobuild(Page404#)
**   }
** <pre
** 
** @uses a MappedConfig of 'Type:ErrProcessor' where 'Type' is a subclass of 'Err' or a mixin.
const class ErrProcessors {
	
	private const StrategyRegistry errProcessorStrategy
	
	internal new make(Type:ErrProcessor errProcessors) {
		errProcessors.keys.each |type| {
			if (type.isClass && !type.fits(Err#))
				throw BedSheetErr(BsMsgs.errProcessorsNotErrType(type))
		}
		this.errProcessorStrategy = StrategyRegistry(errProcessors)
	}
	
	internal Obj processErr(Err err) {
		get(err.typeof).process(err)
	}

	internal ErrProcessor get(Type errType) {
		return errProcessorStrategy.findBestFit(errType)
	}
	
}
