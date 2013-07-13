using afIoc::Inject
using web::WebOutStream
using web::WebRes

** Shamelessly based on 'draft's err page
internal const class HttpStatusPage500 : HttpStatusProcessor {
	private const static Log log := Utils.getLog(HttpStatusPage500#)
	
	@Inject private const MoustacheTemplates 	moustaches
	@Inject	private const HttpRequest  			request
	@Inject	private const HttpResponse 			response
	
	internal new make(|This|in) { in(this) }

	override Obj process(HttpStatus httpStatus) {
	 	logErr(httpStatus.cause)

		title			:= "${httpStatus.code} - " + WebRes.statusMsg[httpStatus.code]
		bedSheetCss		:= typeof.pod.file(`/res/web/bedSheet.css`).readAllStr
		alienHeadSvg	:= typeof.pod.file(`/res/web/alienHead.svg`).readAllStr
		bedSheetHtml	:= typeof.pod.file(`/res/web/bedSheet.moustache`)

		html := moustaches.renderFromFile(bedSheetHtml, [
			"title"			: title,
			"bedSheetCss"	: bedSheetCss,
			"alienHeadSvg"	: alienHeadSvg,
			"content"		: content(httpStatus)
		])
		
		if (!response.isCommitted)	// a sanity check
			response.setStatusCode(httpStatus.code)
		
		return TextResponse.fromHtml(html)
	}	
	
	private Str content(HttpStatus httpStatus) {
		// TODO: only print the gubbins in devMode 

		buf := StrBuf()
		out := WebOutStream(buf.out)
		
		// msg
		msg	  := httpStatus.cause?.msg ?: httpStatus.msg
		h1Msg := msg.split('\n').join("<br/>") { it.toXml }
		out.h1.w(h1Msg).h1End
		out.hr
			
		// req headers
		out.table
		request.headers.each |v,k| { out.tr.td.w(k).tdEnd.td.w(v).tdEnd.trEnd }
		out.tableEnd
		out.hr
		
		// TODO: print thread locals
			
		// stack trace
		if (httpStatus.cause != null) {
			out.pre
			out.writeChars(Utils.traceErr(httpStatus.cause, 50))
			out.preEnd
		}

		return buf.toStr
	}

	private Void logErr(Err? err) {
		if (err == null) return
		
		buf := StrBuf()
		buf.add("$err.msg - $request.uri\n")
		
		buf.add("\nHeaders:\n")
		request.headers.each |v,k| { buf.add("  $k: $v\n") }

		if (request.form != null) {
			buf.add("\nForm:\n")
			request.form.each |v,k| { buf.add("  $k: $v\n") }
		}
		
		buf.add("\nLocales:\n")
		request.locales.each |v,k| { buf.add("  $k: $v\n") }
		
		buf.add("\nStack Trace:\n")
		Utils.traceErr(err, 50).splitLines.each |s| { buf.add("$s\n") }
		log.err(buf.toStr.trim)
	}		
}
