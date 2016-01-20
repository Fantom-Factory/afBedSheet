using afIoc::Inject
using web::WebOutStream

@NoDoc	// Advanced use only
const class NotFoundPrinterHtml {
	@Inject	private const Log log

	private const |WebOutStream out|[]	printers

	new make(|WebOutStream out|[] printers, |This|in) {
		in(this)
		this.printers = printers
	}
	
	Str toHtml() {
		buf := StrBuf()
		out := WebOutStream(buf.out)

		printers.each |print| { 
			try {
				print.call(out)
			} catch (Err e) {
				log.warn("Err when printing 404...", e)
				out.p.w("ERROR!").pEnd
			}
		}

		return buf.toStr
	}
}

internal const class NotFoundPrinterHtmlSections {
	@Inject	private const HttpRequest	request
	@Inject	private const FileHandler	fileHandler
	@Inject	private const PodHandler	podHandler
	@Inject	private const Routes		routes

	new make(|This|in) { in(this) }
	
	Void printRouteCode(WebOutStream out) {
		page := typeof.pod.file(`/res/web/404Page.html`).readAllStr
		page  = page.replace("{{{ route }}}", request.url.pathOnly.toStr)
		out.w(page)
	}
	
	Void printFileHandlers(WebOutStream out) {
		if (fileHandler.directoryMappings.size > 0 || podHandler.baseUrl != null) {
			title(out, "File Handlers")
			map := Str:Str[:] 
			fileHandler.directoryMappings.each |v, k|{ map["${k}*"] = "${v}*" }
			if (podHandler.baseUrl != null) {
				map["${podHandler.baseUrl}*"] = "fan://*"
			}
			prettyPrintMap(out, map, true)
		}
	}
	
	Void printBedSheetRoutes(WebOutStream out) {
		if (!routes.routes.isEmpty) {
			title(out, "BedSheet Routes")

			out.table
			routes.routes.each |r| { 
				w(out, r.matchHint, r.responseHint)
			}
			out.tableEnd
		}
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

	private static Void title(WebOutStream out, Str title) {
		out.h2("id=\"${title.fromDisplayName}\"").w(title).h2End
	}
	
	private static Void w(WebOutStream out, Str key, Obj? val) {
		out.tr.td.writeXml(key).tdEnd.td.writeXml(val?.toStr ?: "null").tdEnd.trEnd
	}
}
