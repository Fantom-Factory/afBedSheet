using afIoc::Inject
using afIoc::Scope

** Public in case someone wants to switch on method calling via IoC.
** pre>
** @Contribute { serviceType=ResponseProcessors# }
** Void contributeResponseProcessors(Configuration config) {
**     processor = config.auto(MethodCallProcessor#, null, [MethodCallProcessor#callWithIoc:true])
**     config.overrideValue(MethodCall#, processor)
** }
** <pre
@NoDoc
const class MethodCallProcessor : ResponseProcessor {
	@Inject private const ObjCache		objCache
	@Inject	private const Scope 		scope
	@Inject	private const ValueEncoders valueEncoders	
 					const Bool			callWithIoc	:= false

	new make(|This|in) { in(this)}

	override Obj process(Obj response) {
		methodCall := (MethodCall) response
		
		handler := methodCall.method.isStatic ? null : objCache[methodCall.method.parent]
		result	:= null
		
		if (callWithIoc)
			// use afIoc to call the method, injecting in any extra params
			// This may seem pointless for routes (which need to match all params on the uri) but it *may* prove useful for
			// other uses of MethodCalls. The Jury's out; I may remove this feature if it proves too bloated and under used.
			result	= scope.callMethod(methodCall.method, handler, methodCall.args) 
		else
			// the standard method call
			// The afIoc method call adds SOOOOO much to the stack trace, and if you need services, call a service! 
			result	= methodCall.method.callOn(handler, methodCall.args)

		return (result == null) ? false : result
	}	
}
