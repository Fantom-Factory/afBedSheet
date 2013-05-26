
internal const class IntValueEncoder : ValueEncoder {

	override Str toClient(Obj value) {
		int := (Int) value
		return int.toStr
	}

	override Obj toValue(Str clientValue) {
		clientValue.toInt
	}

}
