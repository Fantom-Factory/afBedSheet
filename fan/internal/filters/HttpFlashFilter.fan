using afIoc::Inject

internal const class HttpFlashFilter : HttpPipelineFilter {
	
	@Inject	private const HttpFlash				httpFlash
	@Inject	private const HttpSession			httpSession

	new make(|This|in) { in(this) }
	
	override Bool service(HttpPipeline handler) {
		
		httpFlash.setReq(httpSession["bedSheet.flash"])
		
		handled := handler.service
		
		httpSession["bedSheet.flash"] = httpFlash.getRes
		
		return handled
	}
}
