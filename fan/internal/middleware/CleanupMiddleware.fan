using afIoc3

** Ensures the `HttpOutStream` is closed and cleans up all data held in the current thread / 
** request. As such, this must always be the first middleware in the pipeline.   
internal const class CleanupMiddleware : Middleware {
	
	@Inject	private const ThreadLocalManager	localManager
	@Inject	private const HttpResponse			httpResponse
	@Inject	private const Scope					scope

	new make(|This|in) { in(this) }
	
	override Void service(MiddlewarePipeline pipeline) {
		
		scope.createChildScope("request") {
			try {
				pipeline.service
	
			} finally {
				// this commits the response (by calling res.out) if it hasn't already
				// e.g. 304's and redirects have no body, so need to be committed here
				httpResponse.out.close
				
				localManager.cleanUpThread
			}
		}
	}
}
