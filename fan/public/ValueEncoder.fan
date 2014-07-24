
** Implement to convert values to and from 'Str' objects. 
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
** 
** IOC Configuration
** =================
** Instances of 'ValueEncoder' should be contributed to the 'ValueEncoders' service and mapped to a 
** 'Type' representing the object it converts. 
** 
** For example, in your 'AppModule' class:
** 
** pre>
**   @Contribute { serviceType=ValueEncoders# }
**   static Void contributeValueEncoders(Configuration conf) {
**     conf[MyEntity#] = conf.autobuild(MyEntityEncoder#)
**   }
** <pre
** 
const mixin ValueEncoder {

	** Encode the given value into a Str.
	abstract Str toClient(Obj value)

	** Decode the given Str back into an Obj.
	abstract Obj toValue(Str clientValue)

}
