
** Implement to define a 'ResponseProcessor'. 
** 
** 'ResponseProcessors' are responsible for processing the return values from request handlers. Often this involves 
** sending content to the client.   
** 
** IOC Configuration
** =================
** Instances of 'ResponseProcessor' should be contributed to the 'ResponseProcessors' service and mapped to an 
** 'Type' representing the object it handles. 
** 
** For example, in your 'AppModule' class:
** 
** pre>
** @Contribute { serviceType=ResponseProcessors# }
** static Void contributeResponseProcessors(Configuration config) {
**     config[User#] = UserInfoPage()
** }
** <pre
const mixin ResponseProcessor {
	
	** Return 'true' if a response has been sent to the client and all processing has finished. 
	** Else return a response  object for further processing, example, `Text`. 
	abstract Obj process(Obj response)
		
}
