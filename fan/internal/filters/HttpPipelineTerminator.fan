using afIoc::Inject
using afIoc::Registry

const internal class HttpPipelineTerminator : HttpPipeline {

	@Inject	private const Registry				registry
	@Inject	private const ResponseProcessors	responseProcessors  
	
	@Inject	private const Routes				routes
	@Inject	private const HttpRequest			httpRequest

	new make(|This|in) { in(this) }

	override Bool service() {
		// TODO: have a way to disble the welcome page if filters have been added
		// if no routes have been defined, return the default 'BedSheet Welcome' page
		if (routes.routes.isEmpty) {
			welcomePage := ((WelcomePage) registry.autobuild(WelcomePage#)).service
			return responseProcessors.processResponse(welcomePage)
		}

		throw HttpStatusErr(404, BsErrMsgs.route404(httpRequest.modRel, httpRequest.httpMethod))
	}	
}
