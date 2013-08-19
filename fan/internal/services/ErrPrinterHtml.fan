using afIoc::Inject
using afIoc::IocErr
using afIoc::IocHelper
using web::WebOutStream

internal const class ErrPrinterHtml {
	private const static Log log := Utils.getLog(ErrPrinterHtml#)
	
	private const |WebOutStream out, Err? err|[]	printers

	new make(|WebOutStream out, Err? err|[] printers, |This|in) {
		in(this)
		this.printers = printers
	}
	
	Str httpStatusToHtml(HttpStatus httpStatus) {
		buf := StrBuf()
		out := WebOutStream(buf.out)

		msg	  := (httpStatus.cause != null) ? "${httpStatus.cause.typeof}\n - ${httpStatus.cause.msg}" : httpStatus.msg
		h1Msg := msg.split('\n').join("<br/>") { it.toXml }
		out.h1.w(h1Msg).h1End
		
		printers.each |print| { 
			try {
				print.call(out, httpStatus.cause)
			} catch (Err err) {
				log.warn("Err when printing Err...", err)
			}
		}

		return buf.toStr
	}
}

internal const class ErrPrinterHtmlSections {

	@Config { id="afBedSheet.errPrinter.noOfStackFrames" }
	@Inject	private const Int 			noOfStackFrames
	@Inject	private const HttpRequest	request
	@Inject	private const HttpSession	session

	new make(|This|in) { in(this) }
	
	Void printRequestDetails(WebOutStream out, Err? err) {
		out.h2.w("Request Details").h2End
		out.table
		w(out, "URI",			request.uri)
		w(out, "HTTP Method",	request.httpMethod)
		w(out, "HTTP Version",	request.httpVersion)
		out.tableEnd
	}

	Void printRequestHeaders(WebOutStream out, Err? err) {
		out.h2.w("Request Headers").h2End
		out.table
		request.headers.map.exclude |v, k| { k.equalsIgnoreCase("Cookie") }.each |v,k| { w(out, k, v) }
		out.tableEnd
	}

	Void printFormParameters(WebOutStream out, Err? err) {
		if (request.form != null) {
			out.h2.w("Form Parameters").h2End
			out.table
			request.headers.each |v, k| { w(out, k, v) }
			out.tableEnd
		}
	}

	Void printIocOperationTrace(WebOutStream out, Err? err) {
		if (err != null && (err is IocErr) && ((IocErr) err).operationTrace != null) {
			iocErr := (IocErr) err
			out.h2.w("IoC Operation Trace").h2End
			out.ol
			iocErr.operationTrace.splitLines.each { out.li.writeXml(it).liEnd }
			out.olEnd			
		}
	}

	Void printStackTrace(WebOutStream out, Err? err) {
		if (err != null) {
			out.h2.w("Stack Trace").h2End
			out.pre
			out.writeXml("${err.typeof.qname} : ${err.msg}\n")
			out.writeXml("  " + Utils.traceErr(err, noOfStackFrames).replace(err.toStr, "").trim)
			out.preEnd
		}
	}
	
	Void printSession(WebOutStream out, Err? err) {
		if (session.exists && !session.isEmpty) {
			out.h2.w("Session").h2End
			out.table("class=\"session\"")
			session.map.each |v, k| { w(out, k, v) }
			out.tableEnd
		}
	}

	Void printCookies(WebOutStream out, Err? err) {
		if (!request.cookies.isEmpty) {
			out.h2.w("Cookies").h2End
			out.table("class=\"cookies\"")
			request.cookies.each |v, k| { w(out, k, v) }
			out.tableEnd
		}		
	}

	Void printLocales(WebOutStream out, Err? err) {
		out.h2.w("Locales").h2End
		out.ol
		request.locales.each { out.li.writeXml(it.toStr).liEnd }
		out.olEnd
	}
	
	Void printLocals(WebOutStream out, Err? err) {
		if (!IocHelper.locals.isEmpty) {
			out.h2.w("Thread Locals").h2End
			out.table("class=\"threadLocals\"")
			IocHelper.locals.each |v, k| { w(out, k, v) }
			out.tableEnd
		}
	}

	Void printFantomEnvironment(WebOutStream out, Err? err) {
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

	Void printFantomIndexedProps(WebOutStream out, Err? err) {
		out.h2.w("Fantom Indexed Properties").h2End
		out.table
		Env.cur.indexKeys.each |k| {
			vals := Env.cur.index(k)
			out.tr.td.writeXml(k).tdEnd
			out.td.ul
			vals.each |v| {	out.li.writeXml(v).liEnd }
			out.ulEnd.tdEnd
			out.trEnd				
		}
		out.tableEnd		
	}
	
	Void printEnvironmentVariables(WebOutStream out, Err? err) {
		if (!Env.cur.vars.isEmpty) {
			pathSeparator := Env.cur.vars["path.separator"]?.getSafe(0)
			out.h2.w("Environment Variables").h2End
			out.table
			Env.cur.vars.keys.sort.each |k| {
				vals := Env.cur.vars[k].split(pathSeparator)
				out.tr.td.writeXml(k).tdEnd
				out.td.ul
				vals.each |v| {	out.li.writeXml(v).liEnd }
				out.ulEnd.tdEnd
				out.trEnd
			}
			out.tableEnd
		}
	}
	
	Void printFantomDiagnostics(WebOutStream out, Err? err) {
		out.h2.w("Fantom Diagnostics").h2End
		out.table
		Env.cur.diagnostics.each |v, k| { w(out, k, v) }
		out.tableEnd
	}
	
	private Void w(WebOutStream out, Str key, Obj val) {
		out.tr.td.writeXml(key).tdEnd.td.writeXml(val.toStr).tdEnd.trEnd
	}	
}