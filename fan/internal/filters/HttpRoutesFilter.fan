using afIoc::Inject

** Create instances of 'HttpRoutesFilter' manually so you can pass in your own 'Routes' object with it's own collection
** of routes.
@NoDoc	// used by afPillow
const class HttpRoutesFilter : HttpPipelineFilter {

			private const Routes				routes
	@Inject	private const HttpRequest			httpRequest

	** 'Routes' are passed in manually so different instances of this Filter can hold different collections of 'Routes'.
	new make(Routes routes, |This|in) {
		this.routes = routes
		in(this) 
	}

	override Bool service(HttpPipeline handler) {
		handled := routes.processRequest(httpRequest.modRel, httpRequest.httpMethod)
		return handled ? true : handler.service
	}	
}
