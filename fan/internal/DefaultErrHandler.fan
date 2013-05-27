using afIoc::Inject
using web::WebOutStream

internal const class DefaultErrHandler : ErrHandler {
	private const static Log log := Utils.getLog(DefaultErrHandler#)
	
	@Inject
	private const Request req

	@Inject
	private const Response res
	
	new make(|This|in) { in(this) }
	
	override Void handle(Err err) {
	 	logErr(err)

		buf := StrBuf()
		out := WebOutStream(buf.out)
			
		// send HTML response
		out.docType
		out.html
		out.head
			.title.esc(err.msg).titleEnd
			.style.w("pre,td { font-family:monospace; } td:first-child { color:#888; padding-right:1em; }").styleEnd
		.headEnd
			
		out.body
			
		// msg
		out.h1.esc(err.msg).h1End
		out.hr
			
		// req headers
		out.table
		req.headers.each |v,k| { out.tr.td.w(k).tdEnd.td.w(v).tdEnd.trEnd }
		out.tableEnd
		out.hr
			
		// stack trace
		out.pre
		err.trace(out, ["maxDepth":50])
		out.preEnd

		out.bodyEnd
		out.htmlEnd
	}

	private Void logErr(Err err) {
		buf := StrBuf()
		buf.add("$err.msg - $req.uri\n")
		req.headers.each |v,k| { buf.add("	$k: $v\n") }
		err.traceToStr.splitLines.each |s| { buf.add("	$s\n") }
		log.err(buf.toStr.trim)
	}		
}
