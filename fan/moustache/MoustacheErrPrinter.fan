using afIoc::Inject
using web::WebOutStream

internal const class MoustacheErrPrinter {
	
	@Inject	@Config { id="afBedSheet.moustache.linesOfSrcCode" } 	
	private const Int linesOfSrcCode
	
	new make(|This|in) { in(this) }
	
	Void printHtml(WebOutStream out, Err? err) {
		if (err != null && err is MoustacheErr) {
			srcLoc := ((MoustacheErr) err).srcLoc
			out.h2.w("Moustache Compilation Err").h2End
			
			out.p.w(srcLoc.location).w(" : Line ${srcLoc.errLine}").br
			out.w("&nbsp&nbsp;-&nbsp;").writeXml(srcLoc.errMsg).pEnd
			
			out.div("class=\"srcLoc\"")
			out.table
			srcLoc.srcCode(linesOfSrcCode).each |src, line| {
				if (line == srcLoc.errLine) { out.tr("class=\"errLine\"") } else { out.tr }
				out.td.w(line).tdEnd.td.w(src.toXml).tdEnd
				out.trEnd
			}
			out.tableEnd
			out.divEnd
		}
	}

	Void printStr(StrBuf buf, Err? err) {
		if (err != null && err is MoustacheErr) {
			srcLoc := ((MoustacheErr) err).srcLoc
			buf.add("\nMoustache Compilation Err:\n")
			
			buf.add("  ${srcLoc.location}").add(" : Line ${srcLoc.errLine}\n")
			buf.add("    - ${srcLoc.errMsg}\n\n")
			
			srcLoc.srcCode(linesOfSrcCode).each |src, line| {
				if (line == srcLoc.errLine) { buf.add("==>") } else { buf.add("   ") }
				buf.add("${line.toStr.justr(3)}: ${src}\n".replace("\t", "    "))
			}
		}
	}	
}
