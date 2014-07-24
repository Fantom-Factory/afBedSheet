
** Implement to define a 'HttpStatusProcessor'. 
** 
** 'HttpStatusProcessors' process 'HttpStatus' objects returned from request handler methods, and are mapped to 
** specific status codes. 
** 
** When a 'HttpStatus' object is returned from a request handler method, the 'HttpStatusProcessor' with the matching 
** status code is used to handle it.
** 
** If no matching processor can be found, a default processor is used. You can override the default processor by 
** setting it in 'ApplicationDefaults':
** 
** pre>
** @Contribute { serviceType=ApplicationDefaults# } 
** static Void configureApplicationDefaults(Configuration config) {
**   config[BedSheetConfigIds.defaultHttpStatusProcessor] = config.autobuild(MyStatusPage#)
** }
** <pre
** 
** IOC Configuration
** =================
** Instances of 'HttpStatusProcessor' should be contributed to the 'HttpStatusProcessors' service and mapped to an 
** 'Int' representing the status code it handles. 
** 
** For example, in your 'AppModule' class:
** 
** pre>
** @Contribute { serviceType=HttpStatusProcessors# }
** static Void contributeHttpStatusProcessors(MappedConfig config) {
**     config[404] = My404PageHandler()
** }
** <pre
** 
** @see `BedSheetConfigIds.defaultHttpStatusProcessor` 
const mixin HttpStatusProcessor {
	
	** Process the given `HttpStatus`. Return 'true' if request processing is complete or another 
	** response obj to continue processing. 
	abstract Obj process(HttpStatus httpStatus)
	
}
