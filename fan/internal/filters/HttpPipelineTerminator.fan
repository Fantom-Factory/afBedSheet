using afIoc::Inject
using afIoc::Registry
using afIocConfig::Config

const internal class HttpPipelineTerminator : HttpPipeline {

	@Inject	private const Routes				routes
	@Inject	private const ResponseProcessors	responseProcessors 	
	@Inject	private const HttpRequest			httpRequest
	@Inject	private const BedSheetPage			bedSheetPage

	@Config { id="afBedSheet.disableWelcomePage" }
	@Inject	private const Bool					disbleWelcomePage

	new make(|This|in) { in(this) }

	override Bool service() {
		// if no routes have been defined, return the default 'BedSheet Welcome' page
		if (routes.routes.isEmpty && !disbleWelcomePage)
			return responseProcessors.processResponse(bedSheetPage.renderWelcome)

		throw HttpStatusErr(404, BsErrMsgs.route404(httpRequest.modRel, httpRequest.httpMethod))
	}	
}
