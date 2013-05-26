using afIoc

const class TextResultProcessor : ResultProcessor {
	
	@Inject
	private const Response res
	
	new make(|This|in) { in(this) }
	
	override Void process(Obj result) {
		text := (TextResult) result
		
		res.headers["Content-Type"] 	= text.mimeType.toStr
			
		out := res.out
		out.printLine(text.text)
		out.close
	}
	
}
