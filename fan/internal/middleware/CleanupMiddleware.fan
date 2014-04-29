using afIoc::Inject
using afIoc::Registry
using afIoc::ThreadLocalManager

** Ensures the `HttpOutStream` is closed and cleans up all data held in the current thread / 
** request. As such, this must always be the first middleware in the pipeline.   
internal const class CleanupMiddleware : Middleware {
	
	@Inject	private const ThreadLocalManager	localManager
	@Inject	private const HttpResponse			httpResponse

	new make(|This|in) { in(this) }
	
	override Bool service(MiddlewarePipeline pipeline) {
		try {
			return pipeline.service
		} finally {
			httpResponse.out.close
			localManager.cleanUpThread
		}
	}
}
