
internal const class SrcLocation {
	const Uri	location
	const Int 	errLine
	const Str 	errMsg
	private const Str[]	src
	
	internal new make(Uri location, Int errLine, Str errMsg, Str src) {
		this.location	= location
		this.errLine	= errLine	
		this.errMsg		= errMsg
		this.src 		= src.splitLines
	}

	Int:Str srcCode(Int extra) {
		min := (errLine - 1 - extra).max(0)	// -1 so "Line 1" == src[0]
		max := (errLine - 1 + extra + 1).min(src.size)
		lines := Utils.makeMap(Int#, Str#)
		(min..<max).each { lines[it+1] = src[it] }
		
		while (canTrim(lines))
			trim(lines)
		
		return lines
	}
	
	private Bool canTrim(Int:Str lines) {
		lines.vals.all { it[0].isSpace }
	}

	private Void trim(Int:Str lines) {
		lines.each |val, key| { lines[key] = val[1..-1]  }
	}
}