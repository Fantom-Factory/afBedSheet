using afIoc

internal const class TextResponseProcessor : ResponseProcessor {
	
	@Inject
	private const HttpResponse res
	
	new make(|This|in) { in(this) }
	
	override Obj process(Obj response) {
		text := (TextResponse) response
		
		// 200 is set by default - we don't explicitly set it here 'cos error pages may return
		// TextResponses and we don't wanna override the 500 status code!
//		res.setStatusCode(200)
		
		res.headers["Content-Type"] = text.mimeType.toStr
		res.out.printLine(text.text).close
		
		return true
	}
	
}
