using afIoc::Inject
using web::WebOutStream

@NoDoc
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
	@Inject	private const Routes		routes

	new make(|This|in) { in(this) }
	
	Void printRouteCode(WebOutStream out) {
		page := typeof.pod.file(`/res/web/404Page.html`).readAllStr
		page  = page.replace("{{{ route }}}", request.url.pathOnly.toStr)
		out.w(page)
	}
	
	Void printBedSheetRoutes(WebOutStream out) {
		if (!routes.routes.isEmpty) {
			title(out, "BedSheet Routes")

			out.table
			routes.routes.each |r| { 
				w(out, "${r.httpMethod} - ${r.routeRegex}", r.factory.toStr)
			}
			out.tableEnd
		}
	}

	private Void title(WebOutStream out, Str title) {
		out.h2("id=\"${title.fromDisplayName}\"").w(title).h2End
	}
	
	private Void w(WebOutStream out, Str key, Obj? val) {
		out.tr.td.writeXml(key).tdEnd.td.writeXml(val?.toStr ?: "null").tdEnd.trEnd
	}
}
