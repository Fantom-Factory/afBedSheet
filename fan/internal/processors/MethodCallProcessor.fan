using afIoc
using afConcurrent

** Public in case someone want to switch on method calling via IoC.
** pre>
** @Contribute { serviceType=ResponseProcessors# }
** static Void contributeResponseProcessors(Configuration config) {
**     processor = config.autobuild(MethodCallProcessor#, null, [MethodCallProcessor#methodCallViaIoc:true])
**     config.overrideValue(MethodCall#, processor)
** }
** <pre
@NoDoc
const class MethodCallProcessor : ResponseProcessor {
	@Inject private const ObjCache		objCache
	@Inject	private const Registry 		registry
	@Inject	private const ValueEncoders valueEncoders	
 					const Bool			methodCallViaIoc	:= false

	new make(|This|in) { in(this)}

	override Obj process(Obj response) {
		methodCall := (MethodCall) response
		
		handler := methodCall.method.isStatic ? null : objCache[methodCall.method.parent]
		args 	:= convertArgs(methodCall.method, methodCall.args)
		result	:= null
		
		if (methodCallViaIoc)
			// use afIoc to call the method, injecting in any extra params
			// This may seem pointless for routes (which need to match all params on the uri) but it *may* prove useful for
			// other uses of MethodCalls. The Jury's out; I may remove this feature if it proves too bloated and under used.
			result	= registry.callMethod(methodCall.method, handler, args) 
		else
			// the standard method call
			// The afIoc method call adds SOOOOO much to the stack trace, and if you need services, call a service! 
			result	= methodCall.method.callOn(handler, args)

		return (result == null) ? false : result
	}

	** Convert the Str from Routes into real arg objs
	private Obj?[] convertArgs(Method method, Obj?[] argsIn) {
		try
			return argsIn.map |arg, i -> Obj?| {
				// guard against having more args than the method has params! 
				// Should never happen if the Routes do their job!
				paramType	:= method.params.getSafe(i)?.type
				if (paramType == null)
					return arg
				return arg is Str ? valueEncoders.toValue(paramType, arg) : arg
			}
		// if the args can't be converted then clearly the URL doesn't exist!
		catch (ValueEncodingErr valEncErr) {
			throw HttpStatusErr(404, valEncErr.msg, valEncErr)
		}
	}	
}
