using afIoc::Inject

internal const class TextProcessor : ResponseProcessor {
	
	@Inject	private const HttpRequest	req
	@Inject	private const HttpResponse	res
	
	new make(|This|in) { in(this) }
	
	override Obj process(Obj response) {
		text := (Text) response
		
		// 200 is set by default - we don't explicitly set it here 'cos error pages may return
		// Text objs and we don't wanna override the 500 status code!
//		res.setStatusCode(200)

		// use toBuf so we only (UTF-8) encode the text the once
		buf := text.toBuf
		res.headers.contentType 	= text.contentType
		res.headers.contentLength	= buf.size
		if (req.httpMethod != "HEAD")
			res.out.writeBuf(buf)

		return true
	}
}
