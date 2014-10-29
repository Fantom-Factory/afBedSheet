using afIoc::Inject

** (Service) - Contribute your 'ErrProcessor' implementations to this. 
** 
** @uses a configuration of 'Type:Obj' where 'Type' is a subclass of 'Err' or a mixin.
internal const class ErrProcessor : ResponseProcessor {
	@Inject private const ErrResponses errResponses
	
	new make(|This|in) { in(this) }
	
	override Obj process(Obj err) {
		// FIXME: set err in req
		return errResponses.lookupResponse(err)
	}
}
