using afIoc::Inject

internal const class FlashMiddleware : Middleware {
	
	@Inject	private const HttpFlash				httpFlash
	@Inject	private const HttpSession			httpSession

	new make(|This|in) { in(this) }
	
	override Bool service(MiddlewarePipeline pipeline) {
		
		httpFlash.setReq(httpSession["bedSheet.flash"])
		
		handled := pipeline.service
		
		httpSession["bedSheet.flash"] = httpFlash.getRes
		
		return handled
	}
}
