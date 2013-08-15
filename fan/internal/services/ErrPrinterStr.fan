using afIoc::Contribute
using afIoc::OrderedConfig
using afIoc::Inject
using afIoc::IocHelper
using web::WebOutStream

// FIXME: test when err is null, throw a httpstatus500 with no cause 
internal const class ErrPrinterStr {
	
	private const |StrBuf buf, Err? err|[]	printers

	new make(|StrBuf buf, Err? err|[] printers, |This|in) {
		in(this)
		this.printers = printers
	}

	Str errToStr(Err? err) {
		if (err == null) return Str.defVal
		
		buf := StrBuf()
		buf.add("$err.typeof.qname - $err.msg\n")

		printers.each |print| { print.call(buf, err) }
		
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

	Void printStackTrace(StrBuf buf, Err? err) {
		buf.add("\nStack Trace:\n")
		Utils.traceErr(err, noOfStackFrames).splitLines.each |s| { buf.add("$s\n") }
	}
}
