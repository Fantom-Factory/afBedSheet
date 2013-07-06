using afIoc

internal const class TextResponseProcessor : ResponseProcessor {
	
	@Inject
	private const Response res
	
	new make(|This|in) { in(this) }
	
	override Obj? process(Obj response) {
		text := (TextResponse) response
		
		res.headers["Content-Type"] = text.mimeType.toStr
		res.out.printLine(text.text).close
		
		return null
	}
	
}
