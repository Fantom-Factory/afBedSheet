using afIoc::Inject

internal const class FlashMiddleware : Middleware {
	
	@Inject	private const HttpFlash				httpFlash
	@Inject	private const HttpSession			httpSession

	new make(|This|in) { in(this) }
	
	override Bool service(MiddlewarePipeline pipeline) {
		
		session := httpSession.map
		httpFlash.setReq(session["bedSheet.flash"])
		
		handled := pipeline.service
		
		val := httpFlash.getRes
		if (val == null)
			session.remove("bedSheet.flash")
		else
			session["bedSheet.flash"] = val 
		
		return handled
	}
}
