
** Implement to convert values to and from 'Str' objects. Contribute it to the `ValueEncoders` service. 
** 
** 'ValueEncoders' are responsible for converting 'Strs' from request uri segments into request handler method 
** arguments. 
** 
** In general, Fantom objects use 'toStr()' and 'fromStr()' for Str conversion. While this works well for serialisation,
** it often falls short in the context of a web application. This is because in an application, the object in question 
** is often an entity or DTO from a database, and you need services to create it... which you don't have in a static 
** 'fromStr()' ctor!
** 
** Therefore 'ValueEncoders' allow you to use the standard 'afIoc' dependency injection and any service of your choice. 
const mixin ValueEncoder {

	abstract Str toClient(Obj value)

	abstract Obj toValue(Str clientValue)

}
