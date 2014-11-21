using afIoc::Inject
using afIoc::Registry
using afIocConfig::Config
using concurrent

const internal class MiddlewareTerminator : MiddlewarePipeline {

	@Inject	private const Routes				routes
	@Inject	private const ResponseProcessors	responseProcessors 	
	@Inject	private const HttpRequest			httpRequest
	@Inject	private const HttpResponse			httpResponse
	@Inject	private const BedSheetPages			bedSheetPages
			private const AtomicRef				renderWelcomePageRef	:= AtomicRef()

	@Config { id="afBedSheet.disableWelcomePage" }
	@Inject	private const Bool					disbleWelcomePage
			private const Str[]					status404Methods	:= "GET POST".split
	
	new make(|This|in) { in(this) }

	override Void service() {
		// distinguish between Not Found and Not Implemented depending on the requested HTTP method.
		statusCode := status404Methods.contains(httpRequest.httpMethod) ? 404 : 501
		
		// if no routes have been defined, return the default 'BedSheet Welcome' page
		if (renderWelcomePage) {
			httpResponse.statusCode = statusCode
			responseProcessors.processResponse(bedSheetPages.renderWelcome)
			return
		}

		throw HttpStatusErr(statusCode, BsErrMsgs.route404(httpRequest.url, httpRequest.httpMethod))
	}
	
	private Bool renderWelcomePage() {
		// cache the result - don't want to trawl through all the routes for each and every 404!
		if (renderWelcomePageRef.val == null) {
			renderWelcomePageRef.val = routes.routes.exclude |route->Bool| {
				regexRoute := route as RegexRoute
				return (regexRoute?.response == PodHandler#serviceRoute || regexRoute?.response == FileHandler#serviceRoute)
			}.isEmpty && !disbleWelcomePage
		}
		return renderWelcomePageRef.val 
	}
}
