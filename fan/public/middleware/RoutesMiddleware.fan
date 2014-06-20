using afIoc::Inject
using afIoc::ServiceId

** Create instances of RoutesMiddleware manually so you can pass in multiple 'Routes' objects.
@NoDoc
const class RoutesMiddleware : Middleware {

	@Inject	private const Routes		routes
	@Inject	private const HttpRequest	httpRequest

	new make(|This|in) { in(this) }

	override Bool service(MiddlewarePipeline pipeline) {
		handled := routes.processRequest(httpRequest.modRel, httpRequest.httpMethod)
		if (handled)
			return true
		return pipeline.service
	}	
}
