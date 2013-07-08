using afIoc::Inject

** Prevents IE from caching Ajax and CORS requests by setting the following response http headers:
** 
** pre>
**   Cache-Control: max-age=0,no-cache,no-store,post-check=0,pre-check=0"
**   Expires:       Mon, 26 Jul 1997 05:00:00 GMT"
** <pre
const class IeAjaxCacheBustingFilter {
	
	@Inject
	private const HttpRequest req

	@Inject
	private const HttpResponse res
	
	@Inject
	private const BrowserDetection browserDetection
	
	internal new make(|This|in) { in(this) }
	
	** 
	** 'uri' param not used.
	public Bool service(Uri uri := ``) {

		if (browserDetection.isInternetExplorer) {
			// IE CORS requests from XDomainRequest don't set 'X-Requested-With' HTTP header. 
			// Bloody typical!!
			if (req.isXmlHttpRequest || req.headers.containsKey("Origin")) {
				// prevent IE from caching ajax calls
				// see http://www.codecouch.com/2009/01/how-to-stop-internet-explorer-from-caching-ajax-requests/
				res.headers["Cache-Control"] 	= "max-age=0,no-cache,no-store,post-check=0,pre-check=0"
				res.headers["Expires"]			= "Mon, 26 Jul 1997 05:00:00 GMT"
			}
		}
		
		return false
	}
}
