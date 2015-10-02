using afIoc3::Inject
using web::WebUtil

** Pipes the 'InStream' to res.out, closing the 'InStream'.
internal const class InStreamProcessor : ResponseProcessor {
	
	@Inject	private const HttpResponse 	res
	
	new make(|This|in) { in(this) }
	
	override Obj process(Obj inStreamObj) {
		in := (InStream) inStreamObj

		// if we don't throw this, Wisp does, only it gets swallowed server side as the response is comitted 
		if (res.headers.contentLength == null && res.headers.contentType == null)
			throw BedSheetErr("Must set Content-Length or Content-Type to stream content")

		in.pipe(res.out, null, true)

		return true
	}	
}
