using afIoc::Inject
using afIoc::Registry
using web::WebOutStream
using web::WebRes

** Sends the status code and msg in `HttpStatusErr` to the client. 
internal const class HttpStatusErrProcessor : ErrProcessor {

	@Inject
	private const Registry registry
	
	new make(|This|in) { in(this) }
	
	override Obj process(Err e) {
		HttpStatusErr err := (HttpStatusErr) e

		// TODO: log filter please!
//		Env.cur.err.printLine("${err.statusCode} ${err.msg} - ${req.uri}")

		// TODO: have status code handlers
		statusCode	:= err.statusCode
		statusMsg 	:= WebRes.statusMsg[statusCode]
		
		// print markup ourselves and not res.sendErr() so we have more control over closing res.out
		buf := Buf()
		bufOut := WebOutStream(buf.out)
		bufOut.docType
		bufOut.html
		bufOut.head.title.w("$statusCode ${statusMsg}").titleEnd.headEnd
		bufOut.body
		bufOut.h1.w(statusMsg).h1End
		bufOut.w(err.msg).nl
		bufOut.bodyEnd
		bufOut.htmlEnd
		
		if (!webRes.isCommitted)
			webRes.statusCode = statusCode
		html := buf.flip.readAllStr
		
		return TextResponse.fromHtml(html)
	}
	
	private WebRes webRes() {
		registry.dependencyByType(WebRes#)
	}
}
