using afIoc::Contribute
using afIoc::OrderedConfig
using afIoc::IocErr
using afIoc::Inject
using afIoc::IocHelper
using afIoc::NotFoundErr
using afIocConfig::Config
using web::WebOutStream
using afPlastic::SrcCodeErr

** (Service) - 
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
}

internal const class ErrPrinterStrSections {

	@Config { id="afBedSheet.plastic.srcCodeErrPadding" } 	
	@Inject	private const Int			srcCodePadding	
	
	@Config { id="afBedSheet.errPrinter.noOfStackFrames" }
	@Inject	private const Int 			noOfStackFrames
	
	@Inject	private const HttpRequest	request
	@Inject	private const HttpSession	session

	new make(|This|in) { in(this) }

	Void printCauses(StrBuf buf, Err? err) {
		causes := Err[,]
		forEachCause(err, Err#) |Err cause| { causes.add(cause) }
		if (causes.size <= 1)	// don't bother if there are no causes
			return
		
		buf.add("\nCauses:\n")
		causes.each |Err cause, Int i| {
			indent := "".padl(i * 2)
			buf.add("  ${indent}${cause.typeof.qname} - ${cause.msg}\n")
		}
	}

	Void printAvailableValues(StrBuf buf, Err? err) {
		forEachCause(err, NotFoundErr#) |NotFoundErr notFoundErr| {
			buf.add("\nAvailable Values:\n")
			notFoundErr.availableValues.each { buf.add("  $it\n") }
		}
	}

	Void printIocOperationTrace(StrBuf buf, Err? err) {
		if (err != null && (err is IocErr) && ((IocErr) err).operationTrace != null) {
			iocErr := (IocErr) err
			buf.add("\nIoC Operation Trace:\n")
			iocErr.operationTrace.splitLines.each |op, i| { buf.add("  [${(i+1).toStr.justr(2)}] $op\n") }
		}
	}

	Void printSrcCodeErrs(StrBuf buf, Err? err) {
		forEachCause(err, SrcCodeErr#) |SrcCodeErr srcCodeErr| {
			srcCode 	:= srcCodeErr.srcCode
			title		:= srcCodeErr.typeof.name.toDisplayName	
			buf.add("\n${title}:\n")
			buf.add(srcCode.srcCodeSnippet(srcCodeErr.errLineNo, srcCodeErr.msg, srcCodePadding))	
		}
	}	

	Void printStackTrace(StrBuf buf, Err? err) {
		if (err != null) {
			// special case for wrapped IocErrs, unwrap the err if it adds nothing
			if (err is IocErr && err.msg == err.cause?.msg)
				err = err.cause
			buf.add("\nStack Trace:\n")
			buf.add("  ${err.typeof.qname} : ${err.msg}\n")
			trace := "  " + Utils.traceErr(err, noOfStackFrames).replace(err.toStr, "").trim
			buf.add(trace)
			buf.add("\n")
		}
	}

	Void printRequestDetails(StrBuf buf, Err? err) {
		buf.add("\nRequest Details:\n")
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
	
	private Void forEachCause(Err? err, Type causeType, |Obj| f) {
		while (err != null) {
			if (err.typeof.fits(causeType))
				f(err)
			err = err.cause			
		}		
	}	
}
