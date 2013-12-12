using afIoc::Inject

const internal class HttpRouteFilter : HttpPipelineFilter {

	@Inject	private const Routes				routes
	@Inject	private const HttpRequest			httpRequest

	new make(|This|in) { in(this) }

	// TODO: manually create this filter, passing in routes, so we can create many layers.
	override Bool service(HttpPipeline handler) {
		handled := routes.processRequest(httpRequest.modRel, httpRequest.httpMethod)
		return handled ? true : handler.service
	}	
}
