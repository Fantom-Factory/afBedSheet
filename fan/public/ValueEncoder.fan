
const mixin ValueEncoder {

	abstract Str toClient(Obj value)

	abstract Obj toValue(Str clientValue)

}
