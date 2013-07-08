using afIoc::Inject

** @see `https://developer.mozilla.org/en-US/docs/Browser_detection_using_the_user_agent`
internal const class BrowserDetection {

	@Inject
	internal const HttpRequest request
	
	new make(|This|in) { in(this) }
	
	** Returns 'true' if the client identifies its self as Internet Explorer.
	** 
	** @see `http://www.useragentstring.com/pages/Internet%20Explorer/`
	Bool isInternetExplorer() {
		request.headers["User-Agent"]?.contains(" MSIE ") ?: false
	}
}
