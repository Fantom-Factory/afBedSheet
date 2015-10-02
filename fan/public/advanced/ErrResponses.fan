using afIoc3::Inject
using afIocConfig::Config

** (Service) - Contribute your Err responses to this. 
** 
** @uses a configuration of 'Type:Obj' where 'Type' is a subclass of 'Err' or a mixin.
@NoDoc	// Don't overwhelm the masses!
const mixin ErrResponses {
	
	abstract Obj lookup(Err err)
}

internal const class ErrResponsesImpl : ErrResponses {
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
	
	override Obj lookup(Err err) {
		errResponseLookup.findParent(err.typeof, false) ?: defaultErrResponse
	}
}
