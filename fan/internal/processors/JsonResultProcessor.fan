using afIoc::Inject

internal const class JsonResultProcessor : ResultProcessor {

	@Inject
	private const Response res
	
	new make(|This|in) { in(this) }
	
	override Void process(Obj result) {
		json := (JsonResult) result

		res.headers["Content-Type"] 	= "application/json; charset=utf-8"

		// TODO: check req headers for ajax and IE before adding these
		// TODO: check these req headers don't already exist - warn if they do
		// TODOTO: move this into a filter or such so ALL ajax calls may benifeit form the behaviour
		// prevent IE from caching ajax calls
		// see http://www.codecouch.com/2009/01/how-to-stop-internet-explorer-from-caching-ajax-requests/
		res.headers["Cache-Control"] 	= "max-age=0,no-cache,no-store,post-check=0,pre-check=0"
		res.headers["Expires"]			= "Mon, 26 Jul 1997 05:00:00 GMT"
		
		out := res.out
		out.printLine(json.toJsonStr)
		out.close
	}
	
}
