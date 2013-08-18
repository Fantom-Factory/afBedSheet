
const class MoustacheErr : Err {

	internal const SrcLocation srcLoc
	internal const Int linesOfCode

	internal new make(SrcLocation srcLoc, Str msg, Int linesOfCode := 5) : super(msg, cause) {
		this.srcLoc = srcLoc
		this.linesOfCode = linesOfCode
	}

	override Str toStr() {
		buf := StrBuf()
		buf.add("${typeof.qname}: ${msg}")
		buf.add("\nMoustache Compilation Err:\n")

		buf.add("  ${srcLoc.location}").add(" : Line ${srcLoc.errLine}\n")
		buf.add("    - ${srcLoc.errMsg}\n\n")
		
		srcLoc.srcCode(linesOfCode).each |src, line| {
			if (line == srcLoc.errLine) { buf.add("==>") } else { buf.add("   ") }
			buf.add("${line.toStr.justr(3)}: ${src}\n".replace("\t", "    "))
		}

		buf.add("\nStack Trace:")
		return buf.toStr
	}
}
