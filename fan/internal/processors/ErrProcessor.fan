using afIoc::Inject

internal const class ErrProcessor : ResponseProcessor {
	@Inject private const HttpRequest	httpRequest
	@Inject private const HttpResponse	httpResponse
	@Inject private const ErrResponses	errResponses
	
	new make(|This|in) { in(this) }
	
	override Obj process(Obj err) {
		httpRequest.stash[BsConstants.stash_err] = err
		
		// a sanity check
		if (!httpResponse.isCommitted) {
			httpResponse.statusCode = 500
			httpResponse.headers.cacheControl = "private, max-age=0, no-store"
		}

		return errResponses.lookup(err)
	}
}
