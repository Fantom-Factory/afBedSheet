using afIoc::Inject

const internal class HttpRouteService : HttpPipeline {

	@Inject	private const Routes				routes
	@Inject	private const ResponseProcessors	responseProcessors
	@Inject	private const HttpRequest			httpRequest

	new make(|This|in) { in(this) }

	override Bool service() {
		response := routes.processRequest(httpRequest.modRel, httpRequest.httpMethod)
		responseProcessors.processResponse(response)
		return true
	}	
}
