using afBeanUtils::NotFoundErr
using afIoc
using afIocConfig::Config
using afIocConfig::ConfigSource
using afConcurrent::ActorPools
using web::WebOutStream

** (Service) - public, 'cos it's useful for emails. 
@NoDoc	// Advanced use only
const class ErrPrinterHtml {
	@Inject	private const Log log
		
	const Str:|WebOutStream out, Err? err|	printerFuncs

	new make(Str:|WebOutStream out, Err? err| printerFuncs, |This|in) {
		in(this)
		this.printerFuncs = printerFuncs
	}
	
	Str errToHtml(Err? err) {
		buf := StrBuf()
		out := WebOutStream(buf.out)

		if (err != null) {
			msg	  := "${err.typeof}\n - ${err.msg}"
			// 512 chars is about 15 lines of h1 text - should be plenty!
			// It gets confusing if the web page is ALL h1 text, so we limit it
			if (msg.size > 512)
				msg = msg[0..<508] + "..."
	
			h1Msg := msg.split('\n').join("<br/>") { it.toXml }
			out.h1.w(h1Msg).h1End
		}
		
		printerFuncs.each |print| { 
			try {
				print.call(out, err)
			} catch (Err e) {
				log.warn("Err when printing Err to HTML - $e.msg", e)
				out.p.w("ERROR!").pEnd
			}
		}

		return buf.toStr
	}
}

internal const class ErrPrinterHtmlSections {
	@Inject	private const StackFrameFilter	frameFilter
	@Inject	private const BedSheetServer	bedServer
	@Inject	private const HttpRequest		request
	@Inject	private const HttpResponse		response
	@Inject	private const HttpSession		session
	@Inject	private const HttpCookies		cookies
	@Inject	private const ConfigSource		configSrc
	@Inject	private const FileHandler		fileHandler
	@Inject	private const PodHandler		podHandler
	@Inject	private const Routes			routes
	@Inject	private const ActorPools		actorPools
	@Inject	private const |->MiddlewarePipeline|	middleware

	new make(|This|in) { in(this) }

	Void printCauses(WebOutStream out, Err? err) {
		causes := ErrPrinterStrSections.isolateCauses(err)
		if (causes.size <= 1) return

		title(out, "Causes")
		out.pre

		causes.each |Str cause, Int i| {
			indent := "".padl(i*2)
			out.writeXml("${indent}${cause}\n")
		}
		out.preEnd
	}
	
	Void printAvailableValues(WebOutStream out, Err? err) {
		forEachCause(err, NotFoundErr#) |NotFoundErr notFoundErr->Bool| {
			title(out, notFoundErr.valueMsg)
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

	Void printStackTrace(WebOutStream out, Err? err) {
		stacks := ErrPrinterStrSections.isolateStackFrames(err) 
		if (stacks.size == 0) return

		// special case for wrapped IocErrs, unwrap the err if it adds nothing 
		if (err is IocErr && err.msg == err.cause?.msg)
			err = err.cause			
		title(out, "Stack Trace")
		
		script := """var box = document.getElementById("stackFrameCheckbox");
		             box.addEventListener("click", function() {
		             	document.getElementById("stackFrames").className = box.checked ? "hideBoring" : "";
		             });"""
		out.div
		out.printLine("""<label><input type="checkbox" id="stackFrameCheckbox" value="wotever" checked="checked"/> Hide boring stack frames</label> """)
		out.script.w(script).scriptEnd
		out.divEnd
		
		csp := response.headers.contentSecurityPolicy
		if (csp != null) {
			scriptSrc := csp.get("script-src", "")
			if (!scriptSrc.split.contains("'unsafe-inline'")) {
				if (!scriptSrc.isEmpty) scriptSrc += " "
				csp["script-src"] = scriptSrc + "'sha256-" + ("\n"+script).toBuf.toDigest("SHA-256").toBase64 + "'"
				response.headers.contentSecurityPolicy = csp
			}
		}

		out.pre("id=\"stackFrames\" class=\"hideBoring\"")
		stacks.each |stack, i| {
			indent := "".padl(i * 2)
			stack.each |frame| {
				css := frame.startsWith(" ") && frameFilter.filter(frame) ? "dull" : "okay"
				out.span("class=\"${css}\"")
				out.writeXml("  ${indent}${frame}\n")
				out.spanEnd
			}
		}
		out.preEnd
	}

	Void printRequestDetails(WebOutStream out, Err? err) {
		title(out, "Request Details")
		out.table
		w(out, "URI",			bedServer.path + request.url.relTo(`/`))
		w(out, "HTTP Method",	request.httpMethod)
		w(out, "HTTP Version",	request.httpVersion)
		out.tableEnd
	}

	Void printRequestHeaders(WebOutStream out, Err? err) {
		title(out, "Request Headers")
		map := request.headers.val.exclude |v, k| { k.equalsIgnoreCase("Cookie") } 
		prettyPrintMap(out, map, true)
	}

	Void printFormParameters(WebOutStream out, Err? err) {
		try // req.form can throw Errs if badly formatted
			if (request.body.form != null) {
				title(out, "Form Parameters")
				prettyPrintMap(out, request.body.form, true)
			}
		catch (Err eek) {
			title(out, "Form Parameters")
			w(out, "Error",	eek.msg)
		}
	}
	
	Void printSession(WebOutStream out, Err? err) {
		if (session.exists && !session.isEmpty) {
			title(out, "Session")
			prettyPrintMap(out, session.val, true, "session")
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
		if (!configSrc.configMuted.isEmpty) {
			title(out, "Ioc Config Values")
			prettyPrintMap(out, configSrc.configMuted, true)
		}
	}

	Void printFileHandlers(WebOutStream out, Err? err) {
		if (fileHandler.directoryMappings.size > 0) {
			title(out, "File Handlers")
			map := Str:Str[:] 
			fileHandler.directoryMappings.each |v, k|{ map["${k}*"] = "${v}*" }
			if (podHandler.baseUrl != null) {
				map["${podHandler.baseUrl}*"] = "fan://*"
			}
			prettyPrintMap(out, map, true)
		}
	}

	Void printRoutes(WebOutStream out, Err? err) {
		if (!routes.routes.isEmpty) {
			title(out, "BedSheet Routes")
			map := [:] { ordered = true }
			routes.routes.each |r| { map[r.matchHint] = r.responseHint }
			prettyPrintMap(out, map, false)
		}
	}
	
	Void printMiddleware(WebOutStream out, Err? err) {
		title(out, "BedSheet Middleware")
		out.ol
		middleware().middleware.each |ware| { out.li.writeXml(ware.typeof.qname).liEnd }
		out.olEnd		
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
		w(out, "Cur Dir", 	`./`.toFile.normalize.uri)
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
			out.td.tag("ul")
			vals.each |v| {	out.li.writeXml(v).liEnd }
			out.tagEnd("ul").tdEnd
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
				out.td.tag("ul")
				vals.each |v| {	out.li.writeXml(v).liEnd }
				out.tagEnd("ul").tdEnd
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
		Env.cur.findAllPodNames.each |podName| { map[podName] = readPodVersion(podName) }
		prettyPrintMap(out, map, true)
	}

	private static Str readPodVersion(Str podName) {
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
	private static Void title(WebOutStream out, Str title) {
		out.h2("id=\"${title.fromDisplayName}\"").writeXml(title).h2End
	}
	
	private static Void prettyPrintMap(WebOutStream out, Obj:Obj? map, Bool sort, Str? cssClass := null) {
		if (sort) {
			newMap := Str:Obj?[:] { ordered = true } 
			map.keys.sort.each |k| { newMap[k.toStr] = map[k] }
			map = newMap
		}
		out.table(cssClass == null ? null : "class=\"${cssClass}\"")
		map.each |v1, k1| {
			if (v1 is Map && !((Map) v1).isEmpty) {
				// a map inside a map! Used for Actor.Locals()
				m2 := (Map) v1
				out.tr
				out.td.writeXml(k1.toStr).tdEnd
				out.td.tag("ul")
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
				out.tagEnd("ul").tdEnd
				out.trEnd

			} else
				w(out, k1.toStr, v1)
		} 
		out.tableEnd
	}

	private static Void w(WebOutStream out, Str key, Obj? val) {
		out.tr.td.writeXml(key).tdEnd.td.writeXml(val?.toStr ?: "null").tdEnd.trEnd
	}
	
	private static Void forEachCause(Err? err, Type causeType, |Obj->Bool| f) {
		done := false
		while (err != null && !done) {
			if (err.typeof.fits(causeType))
				done = f(err)
			err = err.cause			
		}		
	}		
}
