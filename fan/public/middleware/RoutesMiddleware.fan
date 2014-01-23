using afIoc::Inject
using afIoc::ServiceId

** Create instances of RoutesMiddleware manually so you can pass in multiple 'Routes' objects.
@NoDoc
const class RoutesMiddleware : Middleware {

	@ServiceId { id="RoutesBefore" }
	@Inject	private const Routes		routesBefore
	@Inject	private const Routes		routes
	@ServiceId { id="RoutesAfter" }
	@Inject	private const Routes		routesAfter
	@Inject	private const HttpRequest	httpRequest

	new make(|This|in) { in(this) }

	override Bool service(MiddlewarePipeline pipeline) {
		handled := routes.processRequest(httpRequest.modRel, httpRequest.httpMethod)
		return handled ? true : pipeline.service
	}	
}

@NoDoc
const class RoutesAfterMiddleware : Middleware {
			private const Routes		routes
	@Inject	private const HttpRequest	httpRequest

	new make(Routes routes, |This|in) {
		this.routes = routes
		in(this) 
	}

	override Bool service(MiddlewarePipeline handler) {
		retVal1 := handler.service
		// if the 'after' Route also tries to send data to the client - so be it, let them deal with the error!  
		retVal2 := routes.processRequest(httpRequest.modRel, httpRequest.httpMethod)
		return retVal1 || retVal2
	}	
}
