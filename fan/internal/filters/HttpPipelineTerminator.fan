using afIoc::Inject
using afIoc::Registry

const internal class HttpPipelineTerminator : HttpPipeline {

	@Inject	private const Routes				routes
	@Inject	private const ResponseProcessors	responseProcessors 	
	@Inject	private const HttpRequest			httpRequest
	@Inject	private const BedSheetPage			bedSheetPage

	new make(|This|in) { in(this) }

	override Bool service() {
		// FIXME: have a way to disable the welcome page if filters have been added
		// if no routes have been defined, return the default 'BedSheet Welcome' page
		if (routes.routes.isEmpty)
			return responseProcessors.processResponse(bedSheetPage.renderWelcomePage)

		throw HttpStatusErr(404, BsErrMsgs.route404(httpRequest.modRel, httpRequest.httpMethod))
	}	
}
