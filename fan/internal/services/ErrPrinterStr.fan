using afIoc::Contribute
using afIoc::OrderedConfig
using afIoc::IocErr
using afIoc::Inject
using afIoc::IocHelper
using afIoc::NotFoundErr
using afIocConfig::Config
using afIocConfig::IocConfigSource
using web::WebOutStream
using afPlastic::SrcCodeErr

** (Service) - public, 'cos it's useful for emails. 
@NoDoc
const class ErrPrinterStr {
	private const static Log log := Utils.getLog(ErrPrinterStr#)
	
	private const |StrBuf buf, Err? err|[]	printers

	new make(|StrBuf buf, Err? err|[] printers, |This|in) {
		in(this)
		this.printers = printers
	}

	Str errToStr(Err? err) {
		buf := StrBuf(1000)
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
	
	@Inject	private const StackFrameFilter	frameFilter

	@Inject	private const HttpRequest		request
	@Inject	private const HttpSession		session
	@Inject	private const HttpCookies		cookies
	@Inject	private const IocConfigSource	configSrc
	@Inject	private const Routes			routes

	new make(|This|in) { in(this) }

	Void printCauses(StrBuf buf, Err? err) {
		causes := Err[,]
		forEachCause(err, Err#) |Err cause->Bool| { causes.add(cause); return false }
		if (causes.size <= 1)	// don't bother if there are no causes
			return
		
		buf.add("\nCauses:\n")
		causes.each |Err cause, Int i| {
			indent := "".padl(i * 2)
			buf.add("  ${indent}${cause.typeof.qname} - ${cause.msg}\n")
		}
	}

	Void printAvailableValues(StrBuf buf, Err? err) {
		forEachCause(err, NotFoundErr#) |NotFoundErr notFoundErr->Bool| {
			buf.add("\nAvailable Values:\n")
			notFoundErr.availableValues.each { buf.add("  $it\n") }
			return false
		}
	}

	Void printIocOperationTrace(StrBuf buf, Err? err) {
		// search for the first OpTrace
		forEachCause(err, IocErr#) |IocErr iocErr->Bool| {
			if (iocErr.operationTrace != null) {
				buf.add("\nIoC Operation Trace:\n")
				iocErr.operationTrace.splitLines.each |op, i| { buf.add("  [${(i+1).toStr.justr(2)}] $op\n") }
			}
			return iocErr.operationTrace != null
		}
	}

	Void printSrcCodeErrs(StrBuf buf, Err? err) {
		forEachCause(err, SrcCodeErr#) |SrcCodeErr srcCodeErr->Bool| {
			srcCode 	:= srcCodeErr.srcCode
			title		:= srcCodeErr.typeof.name.toDisplayName	
			buf.add("\n${title}:\n")
			buf.add(srcCode.srcCodeSnippet(srcCodeErr.errLineNo, srcCodeErr.msg, srcCodePadding))
			return false
		}
	}	

	Void printStackTrace(StrBuf buf, Err? err) {
		if (err != null) {
			// special case for wrapped IocErrs, unwrap the err if it adds nothing
			if (err is IocErr && err.msg == err.cause?.msg)
				err = err.cause
			buf.add("\nStack Trace:\n")
			buf.add("  ${err.typeof.qname} : ${err.msg}\n")
			frames := Utils.traceErr(err, noOfStackFrames).replace(err.toStr, "").trim.splitLines.exclude { frameFilter.filter(it) }
			trace := "  " + frames.join("\n")
			buf.add(trace)
			buf.add("\n")
		}
	}

	Void printRequestDetails(StrBuf buf, Err? err) {
		buf.add("\nRequest Details:\n")
		map := [
			"URI"			: request.uri,
			"HTTP Method"	: request.httpMethod,
			"HTTP Version"	: request.httpVersion
		]
		prettyPrintMap(buf, map, false)
	}

	Void printRequestHeaders(StrBuf buf, Err? err) {
		buf.add("\nRequest Headers:\n")
		reqHeaders := request.headers.map.exclude |v, k| { k.equalsIgnoreCase("Cookie") }
		prettyPrintMap(buf, reqHeaders, true)
	}

	Void printFormParameters(StrBuf buf, Err? err) {
		if (request.form != null) {
			buf.add("\nForm:\n")
			prettyPrintMap(buf, request.form, true)
		}
	}
	
	Void printCookies(StrBuf buf, Err? err) {
		if (!cookies.all.isEmpty) {
			buf.add("\nCookies:\n")
			cookieMap := [:]
			cookies.all.each |c| { cookieMap[c.name] = c.val }
			prettyPrintMap(buf, cookieMap, true)
		}	
	}

	Void printLocales(StrBuf buf, Err? err) {
		buf.add("\nLocales:\n")
		request.locales.each { buf.add("  $it\n") }	
	}

	Void printLocals(StrBuf buf, Err? err) {
		if (!Utils.locals.isEmpty) {
			buf.add("\nThread Locals:\n")
			prettyPrintMap(buf, Utils.locals, true)
		}
	}

	Void printSession(StrBuf buf, Err? err) {
		if (session.exists && !session.isEmpty) {
			buf.add("\nSession:\n")
			prettyPrintMap(buf, session.map, true)
		}		
	}
	
	Void printIocConfig(StrBuf buf, Err? err) {
		if (!configSrc.config.isEmpty) {
			buf.add("\nIoc Config Values:\n")
			prettyPrintMap(buf, configSrc.config, true)
		}
	}
	
	Void printRoutes(StrBuf buf, Err? err) {
		if (!routes.routes.isEmpty) {
			buf.add("\nBedSheet Routes:\n")
			map := [:]
			routes.routes.each |r| { 
				map["${r.httpMethod} - ${r.routeRegex}"] = r.factory.toStr
			}
			prettyPrintMap(buf, map, false)
		}
	}
	
	private Void prettyPrintMap(StrBuf buf, Str:Obj? map, Bool sortKeys) {
		buf.add(Utils.prettyPrintMap(map, "  ", sortKeys))
	}
	
	private Void forEachCause(Err? err, Type causeType, |Obj->Bool| f) {
		done := false
		while (err != null && !done) {
			if (err.typeof.fits(causeType))
				done = f(err)
			err = err.cause			
		}		
	}	
}
