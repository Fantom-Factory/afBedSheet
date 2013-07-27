using afIoc::Inject
using afIoc::IocHelper
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

		out.h2.w("Request").h2End
		out.table
		w(out, "URI",			request.uri)
		w(out, "HTTP Method",	request.httpMethod)
		w(out, "HTTP Version",	request.httpVersion)
		out.tableEnd
		
		out.h2.w("Request Headers").h2End
		out.table
		request.headers.map.exclude |v, k| { k.equalsIgnoreCase("Cookie") }.each |v,k| { w(out, k, v) }
		out.tableEnd

		if (request.form != null) {
			out.h2.w("Form Parameters").h2End
			out.table
			request.headers.each |v, k| { w(out, k, v) }
			out.tableEnd
		}
		
		if (httpStatus.cause != null) {
			out.h2.w("Stack Trace").h2End
			out.pre
			out.writeChars(Utils.traceErr(httpStatus.cause, noOfStackFrames))
			out.preEnd
		}

		if (!request.cookies.isEmpty) {
			out.h2.w("Cookies").h2End
			out.table("class=\"cookies\"")
			request.cookies.each |v, k| { w(out, k, v) }
			out.tableEnd
		}

		out.h2.w("Locales").h2End
		out.ol
		request.locales.each { out.li.w(it).liEnd }
		out.olEnd

		if (!IocHelper.locals.isEmpty) {
			out.h2.w("Thread Locals").h2End
			out.table("class=\"threadLocals\"")
			IocHelper.locals.each |v, k| { w(out, k, v) }
			out.tableEnd
		}

		if (httpStatus.cause != null) {
			out.h2.w("Fantom Environment").h2End
			out.table
			w(out, "Cmd Args", 	Env.cur.args)
			w(out, "Home Dir", 	Env.cur.homeDir)
			w(out, "Host", 		Env.cur.host)
			w(out, "Platform", 	Env.cur.platform)
			w(out, "Runtime", 	Env.cur.runtime)
			w(out, "Temp Dir", 	Env.cur.tempDir)
			w(out, "User", 		Env.cur.user)
			w(out, "Work Dir", 	Env.cur.workDir)
			out.tableEnd
		}

		if (httpStatus.cause != null) {
			out.h2.w("Fantom Indexed Properties").h2End
			out.table
			Env.cur.indexKeys.each |k| {
				vals := Env.cur.index(k)
				out.tr.td.w(k).tdEnd
				out.td.ul
				vals.each |v| {	out.li.w(v).liEnd }
				out.ulEnd.tdEnd
				out.trEnd				
			}
			out.tableEnd
		}

		if (!Env.cur.vars.isEmpty) {
			pathSeparator := Env.cur.vars["path.separator"]?.getSafe(0)
			out.h2.w("Environment Variables").h2End
			out.table
			Env.cur.vars.keys.sort.each |k| {
				vals := Env.cur.vars[k].split(pathSeparator)
				out.tr.td.w(k).tdEnd
				out.td.ul
				vals.each |v| {	out.li.w(v).liEnd }
				out.ulEnd.tdEnd
				out.trEnd
			}
			out.tableEnd
		}
		

		if (httpStatus.cause != null) {
			out.h2.w("Fantom Diagnostics").h2End
			out.table
			Env.cur.diagnostics.each |v, k| { w(out, k, v) }
			out.tableEnd
		}

		return buf.toStr
	}
	
//	private Void errSummaryToHtml(WebOutStream out, Err? err) {
//		if (err == null) return
//		
//		out.div("class=\"cause\"")
//		out.h3.w(err.typeof).h3End
//		out.p.w(err.msg).pEnd
//		if (!err.typeof.fields.isEmpty) {
//			out.table
//			err.typeof.fields.each |f| { w(out, f.name, f.get(err).toStr) }
//			out.tableEnd
//		}
//		out.divEnd
//	}
	
	private Void w(WebOutStream out, Str key, Obj val) {
		out.tr.td.w(key).tdEnd.td.w(val).tdEnd.trEnd
	}

	Str errToStr(Err? err) {
		if (err == null) return Str.defVal
		
		buf := StrBuf()
		buf.add("$err.msg\n")

		buf.add("\nRequest:\n")
		buf.add("  URI: ${request.uri}\n")
		buf.add("  HTTP Method: ${request.httpMethod}\n")
		buf.add("  HTTP Version: ${request.httpVersion}\n")
		
		buf.add("\nHeaders:\n")
		request.headers.map.exclude |v,k| { k.equalsIgnoreCase("Cookie") }.each |v,k| { buf.add("  $k: $v\n") }

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
		
		if (!IocHelper.locals.isEmpty) {
			buf.add("\nThread Locals:\n")
			IocHelper.locals.each |v,k| { buf.add("  $k: $v\n") }
		}
		
		buf.add("\nStack Trace:\n")
		Utils.traceErr(err, noOfStackFrames).splitLines.each |s| { buf.add("$s\n") }
		
		return buf.toStr.trim
	}	
	
}