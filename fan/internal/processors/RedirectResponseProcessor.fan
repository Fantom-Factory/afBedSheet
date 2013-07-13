using afIoc::Inject

internal const class RedirectResponseProcessor : ResponseProcessor {

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

		res.setStatusCode(statusCodes[index])
		res.headers["Location"] = redirect.uri.encode
		res.headers["Content-Length"] = "0"

		return true
	}
}
