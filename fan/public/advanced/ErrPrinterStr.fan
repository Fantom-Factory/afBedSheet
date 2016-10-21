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
	
	const Str:|StrBuf buf, Err? err|	printerFuncs

	new make(Str:|StrBuf buf, Err? err| printerFuncs, |This|in) {
		this.printerFuncs = printerFuncs
		in(this)
	}

	Str errToStr(Err? err) {
		buf := StrBuf(1000)
		
		msg	:= (err == null) ? "Err!\n" : "${err?.typeof?.qname} - ${err?.msg}" 
		// 512 chars is about 15 lines of h1 text - should be plenty!
		// we print it all in the causes anyway
		if (msg.size > 512)
			msg = msg[0..<508] + "..."

		buf.add(msg).addChar('\n')

		printerFuncs.each |print| { 
			try {
				print.call(buf, err)
			} catch (Err e) {
				log.warn("Err when printing Err to Str - $e.msg", e)
			}
		}
		
		return buf.toStr
	}
}

internal const class ErrPrinterStrSections {

	private static const Str	typeChar		:= 	Str<|[\.:_\$\p{L}\d]|>
	private static const Regex	basicFrameRegex	:= "^\\s*${typeChar}+\\s*\\(${typeChar}+\\)\$".toRegex
	
	@Inject	private const BedSheetServer	bedServer
	@Inject	private const HttpRequest		request
	@Inject	private const HttpSession		session
	@Inject	private const HttpCookies		cookies
	@Inject	private const ConfigSource		configSrc
	@Inject	private const Routes			routes
	@Inject	private const ActorPools		actorPools
	@Inject	private const |->MiddlewarePipeline|	middleware

	new make(|This|in) { in(this) }

	Void printCauses(StrBuf buf, Err? err) {
		causes := isolateCauses(err)
		if (causes.size <= 1) return

		buf.add("\nCauses:\n")
		causes.each |Str cause, Int i| {
			indent := "".padl(i * 2)
			buf.add("  ${indent}${cause}\n")
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
		stacks := isolateStackFrames(err) 
		if (stacks.size == 0) return

		buf.add("\nStack Trace:\n")
		stacks.each |stack, i| {
			indent := "".padl(i * 2)
			stack.each {
				buf.add("  ${indent}${it}\n")
			}
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
		if (session.exists && !cookies.all.isEmpty) {
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
		if (!configSrc.configMuted.isEmpty) {
			buf.add("\nIoc Config Values:\n")
			prettyPrintMap(buf, configSrc.configMuted, true)
		}
	}
	
	Void printRoutes(StrBuf buf, Err? err) {
		if (!routes.routes.isEmpty) {
			buf.add("\nBedSheet Routes:\n")
			map := [:] { it.ordered = true }
			routes.routes.each |r| { 
				map[r.matchHint] = r.responseHint
			}
			prettyPrintMap(buf, map, false)
		}
	}

	Void printMiddleware(StrBuf buf, Err? err) {
		buf.add("\nBedSheet Middleware:\n")
		middleware().middleware.each |ware, i| {
			buf.add("  ${(i+1).toStr.padl(2)}. ${ware.typeof}\n")
		}
	}

	Void printActorPools(StrBuf buf, Err? err) {
		if (!actorPools.stats.isEmpty) {
			buf.add("\nActor Pools:\n")
			prettyPrintMap(buf, actorPools.stats, true)
		}
	}

	Void printFantomEnvironment(StrBuf buf, Err? err) {
		buf.add("\nFantom Environment:\n")
		map := [:] { it.ordered = true }
		map["Cmd Args"]	= Env.cur.args
		map["Cur Dir"]	= `./`.toFile.normalize.uri
		map["Home Dir"]	= Env.cur.homeDir
		map["Host"]		= Env.cur.host
		map["Platform"]	= Env.cur.platform
		map["Runtime"]	= Env.cur.runtime
		map["Temp Dir"]	= Env.cur.tempDir
		map["User"]		= Env.cur.user
		map["Work Dir"]	= Env.cur.workDir
		prettyPrintMap(buf, map, false)
	}

	private Void prettyPrintMap(StrBuf buf, Str:Obj? map, Bool sortKeys) {
		buf.add(Utils.prettyPrintMap(map, "  ", sortKeys))
	}
	
	private static Void forEachCause(Err? err, Type causeType, |Obj->Bool| f) {
		done  := false
		while (err != null && !done) {
			if (err.typeof.fits(causeType))
				done = f(err)
			err = err.cause			
		}
	}

	static Str[] isolateCauses(Err? err) {
		causes := Str[,]
		lastErr := null as Err
		forEachCause(err, Err#) |Err cause->Bool| {
			if (lastErr?.msg == cause.msg) {
				// the msg was obviously just copied up the chain, so only print it where it first occurred
				causes.pop
				causes.push(lastErr.typeof.qname)
			}

			causes.push("${cause.typeof.qname} - ${cause.msg}")

			lastErr = cause
			return false
		}
		return causes
	}

	// remove all the extra useful shite we bung into the toStr() methods
	static Str[][] isolateStackFrames(Err? err) {
		// special case for wrapped IocErrs, unwrap the err if it adds nothing
		if (err is IocErr && err.msg == err.cause?.msg)
			err = err.cause

		i := 0
		stacks := Str[][,] 
		forEachCause(err, Err#) |Err cause->Bool| {
			frames := isolateStackFrame(cause)
			if (i++ > 0)
				frames.insert(0, "Cause:").insert(0, "")
			stacks.add(frames)
			return false
		}
		return stacks
	}

	private static Str[] isolateStackFrame(Err? err) {
		frames := Utils.traceErr(err).splitLines

		fm := (Int?) null
		to := frames.findIndex |frame, i->Bool| {
			match := basicFrameRegex.matches(frame)

			// hunting for the first frame
			if (fm == null) {
				if (match) fm = i
				return false
			}

			// hunting for the last frame
			return !match
		} ?: -1
		
		return (fm == null || to <= fm) ? frames : frames[fm..<to].insert(0, "${err.typeof.qname}: ${err.msg}") 
	}
}
