
** Responsible for converting values to and from Strs, used to inject values into your web handler methods.
** 
** Contribute to `ValueEncoderSource` to add your own ValueEncoders.
const mixin ValueEncoder {

	abstract Str toClient(Obj value)

	abstract Obj toValue(Str clientValue)

}
