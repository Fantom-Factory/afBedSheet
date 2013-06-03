
** Responsible for converting values to and from Strs, used to inject values into web handler 
** methods.
** 
** Contribute to `ValueEncoderSource` to add your own ValueEncoders.
** 
** A general pattern for Fantom when converting values from Strs is for the Obj in question to 
** implement a static ctor called, 'fromStr()'. While this technique works well for serialisation, 
** it falls short in web app context because:
** 
**  - Static methods can not make use of dependency injection. Given that most ValueEncoders will
**    need to call out a DAO or similar, this is a big limitation.
** 
const mixin ValueEncoder {

	abstract Str toClient(Obj value)

	abstract Obj toValue(Str clientValue)

}
