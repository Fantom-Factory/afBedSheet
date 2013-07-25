using afIoc::Inject
using web::WebUtil

** Pipes the 'InStream' to res.out, closing the 'InStream'.
internal const class InStreamResponseProcessor : ResponseProcessor {
	
	@Inject	private const HttpResponse 	res
	
	new make(|This|in) { in(this) }
	
	override Obj process(Obj inStreamObj) {
		in := (InStream) inStreamObj

		in.pipe(res.out, null, true)

		return true
	}	
}
