
** Implement to convert values to and from 'Str' objects. 
** 
** 'ValueEncoders' are responsible for encoding 'Objs' to and from 'Strs' so they may be used in URLs and HTML forms. 
** 
** In general, Fantom objects use 'toStr()' and 'fromStr()' for Str conversion. While this works well for serialisation,
** it often falls short in the context of a web application. Because in an web application, the object in question 
** is often an entity or DTO from a database, and you need services to create it... which you don't have in a static 
** 'fromStr()' ctor!
** 
** Therefore 'ValueEncoders' allow you to use the standard IoC dependency injection and any service of your choice. 
** 
** 
** 
** Nullablity
** ==========
** 'Obj' values may be 'null', but they must always be converted to a 'Str' instance since you can't express 'null' as 
** a HTML attribute. Bear this in mind when constructing your 'ValueEncoder' for the empty string is used as a 'null' 
** representation. Example:   
** 
** pre>
** syntax: fantom
** const class MyValueEncoder : ValueEncoder {
** 
**     override Str toClient(Obj? value) {
**         if (value == null) return Str.defVal
**         ...
**     }
** 
**     override Obj? toValue(Str clientValue) {
**         if (clientValue.isEmpty) return null
**         ....
**     }
** }
** <pre
** 
** The 'ValueEncoder' method signatures allow you to substitute 'null' for some other default value.
** Example, should you wish, an 'Int' could default to '0' or 'Date' objects could default to today's date.
** 
** 
** 
** IOC Configuration
** =================
** Instances of 'ValueEncoder' should be contributed to the 'ValueEncoders' service and mapped to a 
** 'Type' representing the object it converts. 
** 
** For example, in your 'AppModule' class:
** 
** pre>
**   syntax: fantom
**   @Contribute { serviceType=ValueEncoders# }
**   static Void contributeValueEncoders(Configuration conf) {
**     conf[MyEntity#] = conf.autobuild(MyEntityEncoder#)
**   }
** <pre
** 
const mixin ValueEncoder {

	** Encode the given value into a 'Str'.
	abstract Str toClient(Obj? value)

	** Decode the given 'Str' back into an 'Obj'.
	abstract Obj? toValue(Str clientValue)

}
