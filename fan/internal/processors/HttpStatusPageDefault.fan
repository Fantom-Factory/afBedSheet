using afIoc::Inject
using afIoc::Registry
using web::WebOutStream
using web::WebRes

** Sends the status code and msg in `HttpStatusErr` to the client. 
internal const class HttpStatusPageDefault : HttpStatusProcessor {

	@Inject	private const HttpResponse res
	
	internal new make(|This|in) { in(this) }

	override Obj process(HttpStatus httpStatus) {

		// TODO: log filter please!
//		Env.cur.err.printLine("${err.statusCode} ${err.msg} - ${req.uri}")

		// print markup ourselves and not res.sendErr() so we have more control over closing res.out
		buf := StrBuf()
		bufOut := WebOutStream(buf.out)
		bufOut.docType
		bufOut.html
		bufOut.head.title.w("${httpStatus.code} ${httpStatus.msg}").titleEnd.headEnd
		bufOut.body
		bufOut.h1.w(httpStatus.msg).h1End
		bufOut.w(httpStatus.msg).nl
		bufOut.bodyEnd
		bufOut.htmlEnd
		
		res.setStatusCode(httpStatus.code)		
		return TextResponse.fromHtml(buf.toStr)
	}
	
}
