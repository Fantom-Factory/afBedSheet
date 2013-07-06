using afIoc

internal const class TextResponseProcessor : ResponseProcessor {
	
	@Inject
	private const Response res
	
	new make(|This|in) { in(this) }
	
	override Void process(Obj response) {
		text := (TextResponse) response
		
		res.headers["Content-Type"] = text.mimeType.toStr
		res.out.printLine(text.text).close
	}
	
}
