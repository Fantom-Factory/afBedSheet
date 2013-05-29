
internal const class PinkyEncoder : ValueEncoder {
	
	override Str toClient(Obj value) {
		pinky := (Pinky) value
		return pinky.int.toStr
	}

	override Obj toValue(Str clientValue) {
		Pinky {it.int = clientValue.toInt}
	}
}

internal class Pinky {
	Int? int
}