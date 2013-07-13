using afIoc::Inject
using web::WebOutStream

internal const class ErrPrinter {

	@Config { id="afBedSheet.errPrinter.noOfStackFrames" }
	@Inject	private const Int 			noOfStackFrames
	@Inject	private const HttpRequest	request
	
	new make(|This|in) { in(this) }

	Str errToHtml(HttpStatus httpStatus) {
		buf := StrBuf()
		out := WebOutStream(buf.out)

		msg	  := httpStatus.cause?.msg ?: httpStatus.msg
		h1Msg := msg.split('\n').join("<br/>") { it.toXml }
		out.h1.w(h1Msg).h1End

		out.h2.w("Request URI").h2End
		out.p.b.w(request.uri).bEnd.pEnd
		
		out.h2.w("Request Headers").h2End
		out.table
		request.headers.exclude |v,k| { k.equalsIgnoreCase("Cookie") }.each |v,k| { out.tr.td.w(k).tdEnd.td.w(v).tdEnd.trEnd }
		out.tableEnd

		if (request.form != null) {
			out.h2.w("Form Parameters").h2End
			out.table
			request.headers.each |v,k| { out.tr.td.w(k).tdEnd.td.w(v).tdEnd.trEnd }
			out.tableEnd
		}

		if (!request.cookies.isEmpty) {
			out.h2.w("Cookies").h2End
			out.table
			request.cookies.each |v,k| { out.tr.td("class=\"wrap\"").w(k).tdEnd.td.w(v).tdEnd.trEnd }
			out.tableEnd
		}

		out.h2.w("Locales").h2End
		out.ol
		request.locales.each { out.li.w(it).liEnd }
		out.olEnd
		
		if (httpStatus.cause != null) {
			out.h2.w("Stack Trace").h2End
			out.pre
			out.writeChars(Utils.traceErr(httpStatus.cause, noOfStackFrames))
			out.preEnd
		}

		return buf.toStr
	}

	Str errToStr(Err? err) {
		if (err == null) return Str.defVal
		
		buf := StrBuf()
		buf.add("$err.msg\n")

		buf.add("\nRequest URI:\n")
		buf.add("  ${request.uri}\n")
		
		buf.add("\nHeaders:\n")
		request.headers.exclude |v,k| { k.equalsIgnoreCase("Cookie") }.each |v,k| { buf.add("  $k: $v\n") }

		if (request.form != null) {
			buf.add("\nForm:\n")
			request.form.each |v,k| { buf.add("  $k: $v\n") }
		}
		
		if (!request.cookies.isEmpty) {
			buf.add("\nCookies:\n")
			request.cookies.each |v,k| { buf.add("  $k: $v\n") }
		}
		
		buf.add("\nLocales:\n")
		request.locales.each { buf.add("  $it\n") }
		
		buf.add("\nStack Trace:\n")
		Utils.traceErr(err, noOfStackFrames).splitLines.each |s| { buf.add("$s\n") }
		
		return buf.toStr.trim
	}	
	
}