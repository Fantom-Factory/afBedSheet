using afIoc::Inject
using web::WebOutStream

internal const class MoustacheErrPrinter {
	
//	@Inject	// TODO: config	
	private const Int linesOfSrcCode	:= 5
	
	Void printHtml(WebOutStream out, Err? err) {
		if (err != null && err is MoustacheErr) {
			srcLoc := ((MoustacheErr) err).srcLoc
			out.h2.w("Moustache Compilation Err").h2End
			
			out.p.w(srcLoc.location).w(": Line ${srcLoc.errLine}").br
			out.w("&nbsp&nbsp;-&nbsp;").writeXml(srcLoc.errMsg).pEnd
			
			out.div("class=\"srcLoc\"")
			out.table
			srcLoc.srcCode(5).each |src, line| {
				if (line == srcLoc.errLine) { out.tr("class=\"errLine\"") } else { out.tr }
				out.td.w(line).tdEnd.td.w(src.toXml).tdEnd
				out.trEnd
			}
			out.tableEnd
			out.divEnd
		}
	}

	Void printStr(StrBuf out, Err? err) {
	}
}
