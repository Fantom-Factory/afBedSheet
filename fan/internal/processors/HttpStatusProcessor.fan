using afIoc::Inject
using afIoc::Registry

internal const class HttpStatusProcessor : ResponseProcessor {

	@Inject private const HttpRequest			httpRequest
	@Inject private const HttpResponse			httpResponse
	@Inject private const HttpStatusResponses	httpStatusResponses

	new make(|This|in) { in(this) }
	
	override Obj process(Obj response) {
		httpStatus := (HttpStatus) response
		httpRequest.stash["afBedSheet.httpStatus"] = httpStatus
		
		// a sanity check
		if (!httpResponse.isCommitted) {
			httpResponse.statusCode = httpStatus.code
			httpResponse.headers.cacheControl = "private, max-age=0, no-store"
		}

		return httpStatusResponses.lookup(httpStatus)
	}
}
