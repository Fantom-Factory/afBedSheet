using afIoc::Inject
using afIoc::Registry
using afIocConfig::Config

const internal class MiddlewareTerminator : MiddlewarePipeline {

	@Inject	private const Routes				routes
	@Inject	private const ResponseProcessors	responseProcessors 	
	@Inject	private const HttpRequest			httpRequest
	@Inject	private const HttpResponse			httpResponse
	@Inject	private const BedSheetPages			bedSheetPages

	@Config { id="afBedSheet.disableWelcomePage" }
	@Inject	private const Bool					disbleWelcomePage
			private const Str[]					status404Methods	:= "GET POST".split
	
	new make(|This|in) { in(this) }

	override Bool service() {
		statusCode := status404Methods.contains(httpRequest.httpMethod) ? 404 : 501
		
		// if no routes have been defined, return the default 'BedSheet Welcome' page
		if (routes.routes.isEmpty && !disbleWelcomePage) {
			httpResponse.statusCode = statusCode
			return responseProcessors.processResponse(bedSheetPages.renderWelcome)
		}

		throw HttpStatusErr(statusCode, BsErrMsgs.route404(httpRequest.url, httpRequest.httpMethod))
	}	
}
