using afIoc::Inject
using afIoc::Registry
using afIoc::ThreadStashManager

internal const class HttpCleanupFilter : HttpPipelineFilter {
	
	@Inject	private const Registry				registry
	@Inject	private const ThreadStashManager	stashManager
	@Inject	private const HttpResponse			httpResponse	

	new make(|This|in) { in(this) }
	
	override Bool service(HttpPipeline handler) {
		try {
			return handler.service
		} finally {
			httpResponse.out.close
			stashManager.cleanUpThread			
		}
	}
}
