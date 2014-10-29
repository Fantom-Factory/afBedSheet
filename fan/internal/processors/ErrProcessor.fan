using afIoc::Inject

internal const class ErrProcessor : ResponseProcessor {
	@Inject private const HttpRequest	httpRequest
	@Inject private const ErrResponses	errResponses
	
	new make(|This|in) { in(this) }
	
	override Obj process(Obj err) {
		httpRequest.stash["afBedSheet.err"] = err
		return errResponses.lookup(err)
	}
}
