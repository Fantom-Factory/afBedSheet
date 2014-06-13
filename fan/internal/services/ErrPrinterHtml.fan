using afBeanUtils::NotFoundErr
using afIoc
using afIocConfig::Config
using afIocConfig::IocConfigSource
using web::WebOutStream
using afPlastic::SrcCodeErr

** (Service) - public, 'cos it's useful for emails. 
@NoDoc
const class ErrPrinterHtml {
	@Inject	private const Log log
		
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
				out.p.w("ERROR!").pEnd
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
	
	@Inject	private const StackFrameFilter	frameFilter
	@Inject	private const HttpRequest		request
	@Inject	private const HttpSession		session
	@Inject	private const HttpCookies		cookies
	@Inject	private const IocConfigSource	configSrc
	@Inject	private const Routes			routes
	@Inject	private const ActorPools		actorPools

	new make(|This|in) { in(this) }

	Void printCauses(WebOutStream out, Err? err) {
		causes := Err[,]
		forEachCause(err, Err#) |Err cause->Bool| { causes.add(cause); return false }
		if (causes.size <= 1)	// don't bother if there are no causes
			return
		
		title(out, "Causes")
		out.pre

		causes.each |Err cause, Int i| {
			indent := "".padl(i*2)
			out.w("${indent}${cause.typeof.qname} - ${cause.msg}\n")
		}
		out.preEnd
	}
	
	Void printAvailableValues(WebOutStream out, Err? err) {
		forEachCause(err, NotFoundErr#) |NotFoundErr notFoundErr->Bool| {
			title(out, "Available Values")
			out.ol
			notFoundErr.availableValues.each { out.li.writeXml(it).liEnd }
			out.olEnd
			return false
		}
	}

	Void printIocOperationTrace(WebOutStream out, Err? err) {
		// search for the first OpTrace
		forEachCause(err, IocErr#) |IocErr iocErr->Bool| {
			if (iocErr.operationTrace != null) {
				title(out, "IoC Operation Trace")
				out.ol
				iocErr.operationTrace.splitLines.each { out.li.writeXml(it).liEnd }
				out.olEnd
			}
			return iocErr.operationTrace != null
		}
	}

	Void printSrcCodeErrs(WebOutStream out, Err? err) {
		forEachCause(err, SrcCodeErr#) |SrcCodeErr srcCodeErr->Bool| {
			srcCode 	:= srcCodeErr.srcCode
			title		:= srcCodeErr.typeof.name.toDisplayName
			
			this.title(out, title)
			
			out.p.w(srcCode.srcCodeLocation).w(" : Line ${srcCodeErr.errLineNo}").br
			out.w("&#160;&#160;-&#160;").writeXml(srcCodeErr.msg).pEnd
			
			out.div("class=\"srcLoc\"")
			out.table
			srcCode.srcCodeSnippetMap(srcCodeErr.errLineNo, srcCodePadding).each |src, line| {
				if (line == srcCodeErr.errLineNo) { out.tr("class=\"errLine\"") } else { out.tr }
				out.td.w(line).tdEnd.td.w(src.toXml).tdEnd
				out.trEnd
			}
			out.tableEnd
			out.divEnd
			return false
		}
	}

	Void printStackTrace(WebOutStream out, Err? err) {
		if (err != null) {
			// special case for wrapped IocErrs, unwrap the err if it adds nothing 
			if (err is IocErr && err.msg == err.cause?.msg)
				err = err.cause			
			title(out, "Stack Trace")
			out.pre
			out.writeXml("${err.typeof.qname} : ${err.msg}\n")
			frames := Utils.traceErr(err, noOfStackFrames).replace(err.toStr, "").trim.splitLines.exclude { frameFilter.filter(it) }
			out.writeXml("  " + frames.join("\n"))
			out.preEnd
		}
	}

	Void printRequestDetails(WebOutStream out, Err? err) {
		title(out, "Request Details")
		out.table
		w(out, "URI",			request.uri)
		w(out, "HTTP Method",	request.httpMethod)
		w(out, "HTTP Version",	request.httpVersion)
		out.tableEnd
	}

	Void printRequestHeaders(WebOutStream out, Err? err) {
		title(out, "Request Headers")
		map := request.headers.map.exclude |v, k| { k.equalsIgnoreCase("Cookie") } 
		prettyPrintMap(out, map, true)
	}

	Void printFormParameters(WebOutStream out, Err? err) {
		if (request.form != null) {
			title(out, "Form Parameters")
			prettyPrintMap(out, request.form, true)
		}
	}
	
	Void printSession(WebOutStream out, Err? err) {
		if (session.exists && !session.isEmpty) {
			title(out, "Session")
			prettyPrintMap(out, session.map, true, "session")
		}
	}

	Void printCookies(WebOutStream out, Err? err) {
		if (!cookies.all.isEmpty) {
			title(out, "Cookies")
			cookieMap := [:]
			cookies.all.each |c| { cookieMap[c.name] = c.val }
			prettyPrintMap(out, cookieMap, true, "cookies")
		}		
	}

	Void printLocales(WebOutStream out, Err? err) {
		title(out, "Locales")
		out.ol
		request.locales.each { out.li.writeXml(it.toStr).liEnd }
		out.olEnd
	}
	
	Void printLocals(WebOutStream out, Err? err) {
		if (!Utils.locals.isEmpty) {
			title(out, "Thread Locals")
			prettyPrintMap(out, Utils.locals, true, "threadLocals")
		}
	}

	Void printIocConfig(WebOutStream out, Err? err) {
		if (!configSrc.config.isEmpty) {
			title(out, "Ioc Config Values")
			prettyPrintMap(out, configSrc.config, true)
		}
	}

	Void printBedSheetRoutes(WebOutStream out, Err? err) {
		if (!routes.routes.isEmpty) {
			title(out, "BedSheet Routes")
			map := [:] { ordered = true }
			routes.routes.each |r| { map["${r.httpMethod} - ${r.routeRegex}"] = r.factory.toStr }
			prettyPrintMap(out, map, false)
		}
	}

	Void printActorPools(WebOutStream out, Err? err) {
		if (!actorPools.stats.isEmpty) {
			title(out, "Actor Pools")
			out.table
			prettyPrintMap(out, actorPools.stats, true)
			out.tableEnd
		}
	}

	Void printFantomEnvironment(WebOutStream out, Err? err) {
		title(out, "Fantom Environment")
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
		title(out, "Fantom Indexed Properties")
		out.table
		Env.cur.indexKeys.rw.sort.each |k| {
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
			title(out, "Environment Variables")
			pathSeparator := Env.cur.vars["path.separator"]?.getSafe(0)
			out.table
			Env.cur.vars.keys.rw.sort.each |k| {
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
		prettyPrintMap(out, Env.cur.diagnostics, true)
	}
	
	Void printFantomPods(WebOutStream out, Err? err) {
		out.h2.w("Fantom Pods").h2End
		map := [:]
		// Pod.list throws an Err if any pod is invalid (wrong dependencies etc), using findAllPodNames we don't even 
		// load the pod into memory!
		Env.cur().findAllPodNames.each |podName| { map[podName] = readPodVersion(podName) }
		prettyPrintMap(out, map, true)
	}

	private Str readPodVersion(Str podName) {
		try {
			podFile := Env.cur.findPodFile(podName)
			zip 	:= Zip.open(podFile)
			props	:= zip.contents[`/meta.props`]?.readProps
			zip.close
			return props?.get("pod.version") ?: "NULL"
		} catch (Err e) {
			return "ERROR"
		}		
	}
	
	** If you're thinking of generating a ToC, think about those contributions not in BedSheet...
	** ...and if we add a HTML Helper - do we want add a dependency to BedSheet?
	private Void title(WebOutStream out, Str title) {
		out.h2("id=\"${title.fromDisplayName}\"").w(title).h2End
	}
	
	private Void prettyPrintMap(WebOutStream out, Str:Obj? map, Bool sort, Str? cssClass := null) {
		if (sort) {
			newMap := Str:Obj?[:] { ordered = true } 
			map.keys.sort.each |k| { newMap[k] = map[k] }
			map = newMap
		}
		out.table(cssClass == null ? null : "class=\"${cssClass}\"")
		map.each |v1, k1| {
			if (v1 is Map && !((Map) v1).isEmpty) {
				// a map inside a map! Used for Actor.Locals()
				m2 := (Map) v1
				out.tr
				out.td.writeXml(k1).tdEnd
				out.td.ul
				m2.keys.sort.each |k2, i2|{
					v2 := "$k2:${m2[k2]}"
					if (i2 == 0)
						v2 = "[${v2},"
					else if (i2 == (m2.size-1))
						v2 = "${v2}]"
					else
						v2 = "${v2},"
					out.li.writeXml(v2).liEnd
				}
				out.ulEnd.tdEnd
				out.trEnd

			} else
				w(out, k1, v1)
		} 
		out.tableEnd
	}

	private Void w(WebOutStream out, Str key, Obj? val) {
		out.tr.td.writeXml(key).tdEnd.td.writeXml(val?.toStr ?: "null").tdEnd.trEnd
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
