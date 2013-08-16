using afIoc::Contribute
using afIoc::OrderedConfig
using afIoc::IocErr
using afIoc::Inject
using afIoc::IocHelper
using web::WebOutStream

internal const class ErrPrinterStr {
	private const static Log log := Utils.getLog(ErrPrinterStr#)
	
	private const |StrBuf buf, Err? err|[]	printers

	new make(|StrBuf buf, Err? err|[] printers, |This|in) {
		in(this)
		this.printers = printers
	}

	Str errToStr(Err? err) {
		buf := StrBuf()
		msg	:= (err == null) ? "Err!\n" : "${err?.typeof?.qname} - ${err?.msg}\n" 
		buf.add(msg)

		printers.each |print| { 
			try {
				print.call(buf, err)
			} catch (Err e) {
				log.warn("Err when printing Err...", e)
			}
		}
		
		return buf.toStr.trim
	}

	Str httpStatusToStr(HttpStatus httpStatus) {
		buf	:= StrBuf()
		msg	:= httpStatus.cause?.msg ?: httpStatus.msg
		buf.add("${httpStatus.code} - ${msg}\n")

		printers.each |print| { 
			try {
				print.call(buf, httpStatus.cause)
			} catch (Err err) {
				log.warn("Err when printing Err...", err)
			}
		}
		
		return buf.toStr.trim
	}
}

internal const class ErrPrinterStrSections {

	@Config { id="afBedSheet.errPrinter.noOfStackFrames" }
	@Inject	private const Int 			noOfStackFrames
	@Inject	private const HttpRequest	request
	@Inject	private const HttpSession	session

	new make(|This|in) { in(this) }

	Void printRequest(StrBuf buf, Err? err) {
		buf.add("\nRequest:\n")
		buf.add("  URI: ${request.uri}\n")
		buf.add("  HTTP Method: ${request.httpMethod}\n")
		buf.add("  HTTP Version: ${request.httpVersion}\n")
	}

	Void printRequestHeaders(StrBuf buf, Err? err) {
		buf.add("\nRequest Headers:\n")
		request.headers.map.exclude |v, k| { k.equalsIgnoreCase("Cookie") }.each |v, k| { buf.add("  $k: $v\n") }
	}

	Void printFormParameters(StrBuf buf, Err? err) {
		if (request.form != null) {
			buf.add("\nForm:\n")
			request.form.each |v, k| { buf.add("  $k: $v\n") }
		}
	}

	Void printCookies(StrBuf buf, Err? err) {
		if (!request.cookies.isEmpty) {
			buf.add("\nCookies:\n")
			request.cookies.each |v, k| { buf.add("  $k: $v\n") }
		}	
	}

	Void printLocales(StrBuf buf, Err? err) {
		buf.add("\nLocales:\n")
		request.locales.each { buf.add("  $it\n") }	
	}

	Void printLocals(StrBuf buf, Err? err) {
		if (!IocHelper.locals.isEmpty) {
			buf.add("\nThread Locals:\n")
			IocHelper.locals.each |v, k| { buf.add("  $k: $v\n") }
		}
	}

	Void printSession(StrBuf buf, Err? err) {
		if (session.exists && !session.isEmpty) {
			buf.add("\nSession:\n")
			session.map.each |v, k| { buf.add("  $k: $v\n") }
		}		
	}

	Void printIocOperationTrace(StrBuf buf, Err? err) {
		if (err != null && (err is IocErr) && ((IocErr) err).operationTrace != null) {
			iocErr := (IocErr) err
			buf.add("\nIoC Operation Trace:\n")
			iocErr.operationTrace.splitLines.each |op, i| { buf.add("  [${(i+1).toStr.justr(2)}] $op\n") }
		}
	}

	Void printStackTrace(StrBuf buf, Err? err) {
		if (err != null) {
			buf.add("\nStack Trace:\n")
			buf.add("  ${err.typeof.qname} : ${err.msg}\n")
			trace := "  " + Utils.traceErr(err, noOfStackFrames).replace(err.toStr, "").trim
			buf.add(trace)
		}
	}
}
