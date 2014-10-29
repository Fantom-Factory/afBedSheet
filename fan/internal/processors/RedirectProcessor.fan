using afIoc::Inject

** @see
**  - http://en.wikipedia.org/wiki/List_of_HTTP_status_codes#3xx_Redirection
**  - http://www.iana.org/assignments/http-status-codes/http-status-codes.xml
internal const class RedirectProcessor : ResponseProcessor {

	@Inject	private const HttpRequest 	req
	@Inject	private const HttpResponse 	res

	private static const Version ver10 		:= Version("1.0")
	private static const Version ver11 		:= Version("1.1")

	private static const Int[] statusCodes	:= [301, 302, 302, 308, 307, 303]
	
	new make(|This|in) { in(this) }

	override Obj process(Obj response) {
		redirect := (Redirect) response
		
		index := redirect.type.ordinal
		if (req.httpVersion > ver10)
			index = index + 3

		res.statusCode = statusCodes[index]
		res.headers.location = redirect.uri
		res.headers.contentLength = 0

		return true
	}
}
