using afIoc::Inject
using afIoc::IocErr
using afIoc::IocHelper
using afIoc::NotFoundErr
using afIocConfig::Config
using web::WebOutStream
using afPlastic::SrcCodeErr

** (Service) - 
internal const class ErrPrinterHtml {
	private const static Log log := Utils.getLog(ErrPrinterHtml#)
		
	private const |WebOutStream out, Err? err|[]	printers

	new make(|WebOutStream out, Err? err|[] printers, |This|in) {
		in(this)
		this.printers = printers
	}
	
	Str errToHtml(Err err) {
		buf := StrBuf()
		out := WebOutStream(buf.out)

		msg	  := "${err.typeof}\n - ${err.msg}"
		h1Msg := msg.split('\n').join("<br/>") { it.toXml }
		out.h1.w(h1Msg).h1End
		
		printers.each |print| { 
			try {
				print.call(out, err)
			} catch (Err e) {
				log.warn("Err when printing Err...", e)
			}
		}

		return buf.toStr
	}
}

internal const class ErrPrinterHtmlSections {

	@Config { id="afBedSheet.plastic.srcCodeErrPadding" } 	
	@Inject	private const Int			srcCodePadding	
	
	@Config { id="afBedSheet.errPrinter.noOfStackFrames" }
	@Inject	private const Int 			noOfStackFrames
	
	@Inject	private const HttpRequest	request
	@Inject	private const HttpSession	session
	@Inject	private const HttpCookies	cookies

	new make(|This|in) { in(this) }

	Void printCauses(WebOutStream out, Err? err) {
		causes := Err[,]
		forEachCause(err, Err#) |Err cause| { causes.add(cause) }
		if (causes.size <= 1)	// don't bother if there are no causes
			return
		
		out.h2.w("Causes").h2End
		out.pre

		causes.each |Err cause, Int i| {
			indent := "".padl(i*2)
			out.w("${indent}${cause.typeof.qname} - ${cause.msg}\n")
		}
		out.preEnd
	}
	
	Void printAvailableValues(WebOutStream out, Err? err) {
		forEachCause(err, NotFoundErr#) |NotFoundErr notFoundErr| {
			out.h2.w("Available Values").h2End
			out.ol
			notFoundErr.availableValues.each { out.li.writeXml(it).liEnd }
			out.olEnd
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

	Void printSrcCodeErrs(WebOutStream out, Err? err) {
		forEachCause(err, SrcCodeErr#) |SrcCodeErr srcCodeErr| {
			srcCode 	:= srcCodeErr.srcCode
			title		:= srcCodeErr.typeof.name.toDisplayName
			
			out.h2.w(title).h2End
			
			out.p.w(srcCode.srcCodeLocation).w(" : Line ${srcCodeErr.errLineNo}").br
			out.w("&nbsp;&nbsp;-&nbsp;").writeXml(srcCodeErr.msg).pEnd
			
			out.div("class=\"srcLoc\"")
			out.table
			srcCode.srcCodeSnippetMap(srcCodeErr.errLineNo, srcCodePadding).each |src, line| {
				if (line == srcCodeErr.errLineNo) { out.tr("class=\"errLine\"") } else { out.tr }
				out.td.w(line).tdEnd.td.w(src.toXml).tdEnd
				out.trEnd
			}
			out.tableEnd
			out.divEnd
		}
	}

	Void printStackTrace(WebOutStream out, Err? err) {
		if (err != null) {
			// special case for wrapped IocErrs, unwrap the err if it adds nothing 
			if (err is IocErr && err.msg == err.cause?.msg)
				err = err.cause			
			out.h2.w("Stack Trace").h2End
			out.pre
			out.writeXml("${err.typeof.qname} : ${err.msg}\n")
			out.writeXml("  " + Utils.traceErr(err, noOfStackFrames).replace(err.toStr, "").trim)
			out.preEnd
		}
	}

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
	
	Void printSession(WebOutStream out, Err? err) {
		if (session.exists && !session.isEmpty) {
			out.h2.w("Session").h2End
			out.table("class=\"session\"")
			session.map.each |v, k| { w(out, k, v) }
			out.tableEnd
		}
	}

	Void printCookies(WebOutStream out, Err? err) {
		if (!cookies.all.isEmpty) {
			out.h2.w("Cookies").h2End
			out.table("class=\"cookies\"")
			cookies.all.each |c| { w(out, c.name, c.val) }
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
	
	private Void w(WebOutStream out, Str key, Obj? val) {
		out.tr.td.writeXml(key).tdEnd.td.writeXml(val?.toStr ?: "null").tdEnd.trEnd
	}
	
	private Void forEachCause(Err? err, Type causeType, |Obj| f) {
		while (err != null) {
			if (err.typeof.fits(causeType))
				f(err)
			err = err.cause			
		}		
	}		
}
