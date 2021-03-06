
** Implement to define a 'ResponseProcessor'. 
** 
** 'ResponseProcessors' are responsible for processing the return values from request handlers. Often this involves 
** sending content to the client. 
** 
** Example 'ResponseProcessors' that are provided by BedSheet are:
**  - 'RedirectProcessor' - sets the 'Location' HTTP response header and a corresponding HTTP status code. 
**  - 'TextProcessor' - sets the 'Content-Type' HTTP response header and sends the text to the client.
** 
** IoC Configuration
** =================
** Instances of 'ResponseProcessor' should be contributed to the 'ResponseProcessors' service and mapped to an 
** 'Type' representing the object it handles. 
** 
** For example, in your 'AppModule' class:
** 
** pre>
** syntax: fantom 
** @Contribute { serviceType=ResponseProcessors# }
** Void contributeResponseProcessors(Configuration config) {
**     config[User#] = UserInfoPage()
** }
** <pre
const mixin ResponseProcessor {
	
	** Return 'true' if a response has been sent to the client and all processing has finished. 
	** Else return a response object for further processing, example, `Text` or `HttpStatus`. 
	abstract Obj process(Obj response)
		
}
