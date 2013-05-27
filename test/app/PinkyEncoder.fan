
internal const class PinkyEncoder : ValueEncoder {
	
	override Str toClient(Obj value) {
		pinky := (Pinky) value
		return pinky.toStr
	}

	override Obj toValue(Str clientValue) {
		Pinky{it.str = clientValue}
	}
}

internal class Pinky {
	Str? str
}