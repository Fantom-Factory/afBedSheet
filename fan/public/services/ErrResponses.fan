using afIoc::Inject
using afIocConfig::Config

** (Service) - Contribute your 'ErrProcessor' implementations to this. 
** 
** @uses a configuration of 'Type:Obj' where 'Type' is a subclass of 'Err' or a mixin.
internal const class ErrResponses {
	private const CachingTypeLookup errResponseLookup

	@Inject @Config
	private const Obj defaultErrResponse
	
	internal new make(Type:Obj errResponses, |This|in) {
		in(this)
		errResponses.keys.each |type| {
			if (!type.fits(Err#))
				throw BedSheetErr(BsErrMsgs.errProcessors_notErrType(type))
		}
		this.errResponseLookup = CachingTypeLookup(errResponses)
	}
	
	Obj lookupResponse(Err err) {
		errResponseLookup.findParent(err.typeof, false) ?: defaultErrResponse
	}
}
