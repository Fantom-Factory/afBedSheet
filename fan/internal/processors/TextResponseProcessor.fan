using afIoc::Inject

internal const class TextResponseProcessor : ResponseProcessor {
	
	@Inject
	private const HttpResponse res
	
	new make(|This|in) { in(this) }
	
	override Obj process(Obj response) {
		text := (Text) response
		
		// 200 is set by default - we don't explicitly set it here 'cos error pages may return
		// Text objs and we don't wanna override the 500 status code!
//		res.setStatusCode(200)

		res.headers.contentType = text.mimeType
		res.out.print(text.text)
		
		return true
	}
	
}
