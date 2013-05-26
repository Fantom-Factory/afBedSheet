
internal const class StrValueEncoder : ValueEncoder {

	override Str toClient(Obj value) {
		str := (Str) value
		return str.toStr
	}

	override Obj toValue(Str clientValue) {
		clientValue
	}

}
