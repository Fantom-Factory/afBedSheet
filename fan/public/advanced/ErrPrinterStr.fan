using afBeanUtils::NotFoundErr
using afIoc
using afIocConfig::Config
using afIocConfig::ConfigSource
using afConcurrent::ActorPools
using web::WebOutStream

** (Service) - public, 'cos it's useful for emails. 
@NoDoc	// Advanced use only
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
				log.warn("Err when printing Err - $e.msg")
			}
		}
		
		return buf.toStr.trim
	}
}

internal const class ErrPrinterStrSections {

	@Config { id="afBedSheet.errPrinter.noOfStackFrames" }
	@Inject	private const Int 			noOfStackFrames
	
	@Inject	private const BedSheetServer	bedServer
	@Inject	private const HttpRequest		request
	@Inject	private const HttpSession		session
	@Inject	private const HttpCookies		cookies
	@Inject	private const ConfigSource		configSrc
	@Inject	private const Routes			routes
	@Inject	private const ActorPools		actorPools

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
			buf.add("\n${notFoundErr.valueMsg}\n")
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

	Void printStackTrace(StrBuf buf, Err? err) {
		if (err != null) {
			// special case for wrapped IocErrs, unwrap the err if it adds nothing
			if (err is IocErr && err.msg == err.cause?.msg)
				err = err.cause
			buf.add("\nStack Trace:\n")
			buf.add("  ${err.typeof.qname} : ${err.msg}\n")
			frames := Utils.traceErr(err, noOfStackFrames).replace(err.toStr, "").trim.splitLines
			trace := "  " + frames.join("\n")
			buf.add(trace)
			buf.add("\n")
		}
	}

	Void printRequestDetails(StrBuf buf, Err? err) {
		buf.add("\nRequest Details:\n")
		map := [
			"URI"			: bedServer.path + request.url.relTo(`/`),
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
		try // req.form can throw Errs if badly formatted
			if (request.body.form != null) {
				buf.add("\nForm:\n")
				prettyPrintMap(buf, request.body.form, true)
			}
		catch (Err eek)
			buf.add("\nForm: ${eek.msg}\n")			
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
				map[r.matchHint] = r.responseHint
			}
			prettyPrintMap(buf, map, false)
		}
	}

	Void printActorPools(StrBuf buf, Err? err) {
		if (!actorPools.stats.isEmpty) {
			buf.add("\nActor Pools:\n")
			prettyPrintMap(buf, actorPools.stats, true)
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
