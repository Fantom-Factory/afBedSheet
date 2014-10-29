using afIoc::Inject
using afIoc::Registry

internal const class HttpStatusProcessor : ResponseProcessor {

	@Inject private const HttpRequest			httpRequest
	@Inject private const HttpStatusResponses	httpStatusResponses

	new make(|This|in) { in(this) }
	
	override Obj process(Obj httpStatus) {
		httpRequest.stash["afBedSheet.httpStatus"] = httpStatus
		return httpStatusResponses.lookup(httpStatus)
	}
}
