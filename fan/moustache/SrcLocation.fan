
const class SrcLocation {
	const Uri	resource
	const Int 	line
	private const Str[]	src
	
	internal new make(Uri resource, Str src, Int line) {
		this.resource	= resource
		this.src 		= src.splitLines
		this.line		= line	
	}
	
	Int:Str srcCode(Int extra) {
		min := (line - 1 - extra).max(0)	// -1 so "Line 1" == src[0]
		max := (line - 1 + extra + 1).min(src.size)
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