using afIoc3::Inject

** Create instances of RoutesMiddleware manually so you can pass in multiple 'Routes' objects.
@NoDoc
const class RoutesMiddleware : Middleware {

	@Inject	private const Routes		routes
	@Inject	private const HttpRequest	httpRequest

	new make(|This|in) { in(this) }

	override Void service(MiddlewarePipeline pipeline) {
		handled := routes.processRequest(httpRequest)
		if (!handled)
			pipeline.service
	}	
}
