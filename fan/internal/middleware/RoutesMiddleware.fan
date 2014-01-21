using afIoc::Inject

** Create instances of Route middleware manually so you can pass in your own 'Routes' object with it's own collection
** of routes.
@NoDoc
const class RoutesBeforeMiddleware : Middleware {
			private const Routes		routes
	@Inject	private const HttpRequest	httpRequest

	** 'Routes' are passed in manually so different instances of this middleware can hold different collections of 
	** 'Routes'.
	new make(Routes routes, |This|in) {
		this.routes = routes
		in(this) 
	}

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
