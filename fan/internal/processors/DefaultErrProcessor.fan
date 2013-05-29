using afIoc::Inject
using web::WebOutStream

** Shamelessly based on 'draft's err page
internal const class DefaultErrProcessor : ErrProcessor {
	private const static Log log := Utils.getLog(DefaultErrProcessor#)
	
	@Inject
	private const Request req

	@Inject
	private const Response res
	
	new make(|This|in) { in(this) }
	
	override Obj process(Err err) {
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
		
		// TODO: only print the gubbins in devMode 
		
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
		b := Buf()	// can't trace to a StrBuf
		err.trace(b.out, ["maxDepth":50])
		out.writeChars(b.flip.in.readAllStr)
		out.preEnd

		out.bodyEnd
		out.htmlEnd
		
		res.setStatusCode(500)
		return TextResult.fromHtml(buf.toStr)
	}

	private Void logErr(Err err) {
		buf := StrBuf()
		buf.add("$err.msg - $req.uri\n")
		req.headers.each |v,k| { buf.add("  $k: $v\n") }
		err.traceToStr.splitLines.each |s| { buf.add("  $s\n") }
		log.err(buf.toStr.trim)
	}		
}