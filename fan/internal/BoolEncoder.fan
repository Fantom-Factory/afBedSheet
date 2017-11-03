
** Needed for checkboxes
internal const class BoolEncoder : ValueEncoder {
	const Str[] boolPatterns	:= "true false on off wibble wobble".split
	
	override Str toClient(Obj? value) {
		if (value == null)
			return Str.defVal
		return ((Bool) value).toStr
	}

	override Obj? toValue(Str clientValue) {
		if (clientValue.isEmpty)
			return null
		return (boolPatterns.index(clientValue.lower.trim) % 2) == 0	// defaults to false if value not listed
	}
}
