using afIoc::Inject

internal const class JsonResultProcessor : ResultProcessor {

	@Inject
	private const Request request

	@Inject
	private const Response response
	
	@Inject
	private const BrowserDetection browserDetection
	
	new make(|This|in) { in(this) }
	
	override Void process(Obj result) {
		json := (JsonResult) result

		response.headers["Content-Type"] = "application/json; charset=utf-8"

		if (request.isXmlHttpRequest && browserDetection.isInternetExplorer) {
			// TODO: check these req headers don't already exist - warn if they do
			// TODO: move this into some sorta pipeline filter so ALL ajax calls may benefit from the behaviour

			// prevent IE from caching ajax calls
			// see http://www.codecouch.com/2009/01/how-to-stop-internet-explorer-from-caching-ajax-requests/
			response.headers["Cache-Control"] 	= "max-age=0,no-cache,no-store,post-check=0,pre-check=0"
			response.headers["Expires"]			= "Mon, 26 Jul 1997 05:00:00 GMT"
		}
		
		out := response.out
		out.printLine(json.toJsonStr)
		out.close
	}
	
}
