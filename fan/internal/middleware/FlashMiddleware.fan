using afIoc::Inject

internal const class FlashMiddleware : Middleware {
	
	@Inject	private const HttpFlash		httpFlash
	@Inject	private const HttpSession	httpSession

	new make(|This|in) { in(this) }
	
	override Bool service(MiddlewarePipeline pipeline) {
		httpFlash.setReq(httpSession["bedSheet.flash"])
		
		handled := pipeline.service
		
		val := httpFlash.getRes
		if (val != null)
			httpSession["bedSheet.flash"] = val
		else 
			httpSession.remove("bedSheet.flash")
		
		return handled
	}
}
