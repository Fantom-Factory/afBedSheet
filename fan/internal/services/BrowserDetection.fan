using afIoc::Inject

** @see `https://developer.mozilla.org/en-US/docs/Browser_detection_using_the_user_agent`
internal const mixin BrowserDetection {

	** Returns 'true' if the client identifies its self as Interner Explorer.
	** 
	** @see `http://www.useragentstring.com/pages/Internet%20Explorer/`
	abstract Bool isInternetExplorer()
	
}

internal const class BrowserDetectionImpl : BrowserDetection {
	
	@Inject
	internal const Request request
	
	new make(|This|in) { in(this) }
	
	override Bool isInternetExplorer() {
		request.headers["User-Agent"]?.contains(" MSIE ") ?: false
	}
}
