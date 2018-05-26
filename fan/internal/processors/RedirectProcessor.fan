using afIoc::Inject

** @see
**  - http://en.wikipedia.org/wiki/List_of_HTTP_status_codes#3xx_Redirection
**  - http://www.iana.org/assignments/http-status-codes/http-status-codes.xml
internal const class RedirectProcessor : ResponseProcessor {

	@Inject	private const HttpRequest 	req
	@Inject	private const HttpResponse 	res

	new make(|This|in) { in(this) }

	override Obj process(Obj response) {
		redirect := (Redirect) response
		
		res.statusCode				= redirect.type.statusCode(req.httpVersion)
		res.headers.location		= redirect.location
		res.headers.contentLength	= 0

		return true
	}
}
