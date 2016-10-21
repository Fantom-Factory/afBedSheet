
** Implement to create HTTP request / response loggers.
**
** 'logIncoming()' is called once per request *before* any request processing, and 'logOutgoing()' is called *after* all processing has finished. 
** Here's an example basic logger:
**
** pre>
** syntax: fantom
** 
** using afIoc
** using afConcurrent
**
** const class BasicRequestLogger : RequestLogger {
**     @Inject private const HttpRequest  httpReq
**     @Inject private const HttpResponse httpRes
**     @Inject private const LocalRef     startTimeRef
**     @Inject private const Log          log
**     
**     new make(|This|in) { in(this) }
**     
**     override Void logIncoming() {
**         startTimeRef.val = Duration.now
**     }
** 
**     override Void logOutgoing() {
**         timeTaken := Duration.now.minus(startTimeRef.val).toLocale
**         msg := "${httpReq.httpMethod} ${httpReq.url.encode} ${httpRes.statusCode} in ${timeTaken}"
**         log.info(msg)
**     }
** }
** <pre
**  
** `Middleware` could be used to log HTTP requests, but 'Middleware' is wrapped in an error handling mechanism. 
** So if an error handler changes response, this may not be seen by the logger.
** 
** 'Requestloggers' are invoked *outside* of error handling, so the response seen by the logger IS the response sent to the browser. 
** The caveat to this, is that ALL errors raised by 'RequestLoggers' are simply logged and swallowed. 
** So unless you're monitoring the server logs, you're unlikely to see any logger problems.
** 
**  
**  
** IoC Configuration
** =================
** Instances of 'RequestLogger' should be contributed to the 'RequestLoggers' service. Example: 
** 
**   syntax: fantom 
**   @Contribute { serviceType=RequestLoggers# }
**   Void contributeRequestLoggers(Configuration config) {
**       config.add(MyRequestLogger())
**   }
** 
** A config key is not required, but it's polite to provide one so others may remove it, or order their loggers before or after yours. 
** You can also use IoC to autobuild your logger should it have any dependencies:
** 
**   syntax: fantom 
**   @Contribute { serviceType=RequestLoggers# }
**   Void contributeRequestLoggers(Configuration config) {
**       config["myLogger"] = config.build(MyRequestLogger#)
**   }
**  
const mixin RequestLogger {
	
	** Called *before* all request processing.
	virtual Void logIncoming() { }

	** Called *after* all request processing.
	virtual Void logOutgoing() { }

}
