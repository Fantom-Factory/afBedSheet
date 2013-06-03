
** Responsible for converting values to and from Strs, used to inject values into your web handler 
** methods.
** 
** Contribute to `ValueEncoderSource` to add your own ValueEncoders.
** 
** A general pattern for Fantom when converting values to Strs is for the Obj in question to 
** implement a static factory method called, 'fromStr()'. While this technique works well for 
** serialisation, it falls short in web app context for the following reasons:
** 
**  - Static factory methods can not have dependencies injected. Given that most ValueEncoders will
**    need to call out a DAO or similar, this is a big limitation.
**  - You could find your DAOs via the old skool Resource Locator pattern, but then you run into 
**    the usual issues of replacing them with test implementations.
** 
** TODO: fook it, don't fight it! Use 'fromStr()' as fall back method! Delete Int and Str ValEncs. 
** 
const mixin ValueEncoder {

	abstract Str toClient(Obj value)

	abstract Obj toValue(Str clientValue)

}
