using afIoc3::Inject

internal const class FlashMiddleware : Middleware {
	
	@Inject	private const HttpSession	httpSession

	new make(|This|in) { in(this) }
	
	override Void service(MiddlewarePipeline pipeline) {
				httpSession._initFlash
		try		pipeline.service
		finally	httpSession._finalFlash
	}
}
