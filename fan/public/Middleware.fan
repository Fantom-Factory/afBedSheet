
** Implement to define BedSheet middleware. 
** 
** Define middleware to address cross cutting concerns such as authentication and authorisation.
** 
** HTTP requests are funneled through a stack of middleware until one of them returns 'true', or they reach a 
** terminator. Default middleware include passing the request through the 'Routes' service. The default terminator 
** (should no route be found) raises a 404 error. 
** 
** Middleware may perform processing before and / or after passing the service invocation down the pipeline to other 
** middleware instances. If a Middleware instance handles the request itself, then it should return 'true'. 
** 
** Because middleware effectively wrap other middleware and can terminate the pipeline prematurely, the ordering of
** middleware is extremely important. 'Routes' are processed in middleware named 'Routes' so generally your middleware
** should be contributed *before* or *after* this.
** 
** IOC Configuration
** =================
** Instances of 'Middleware' should be contributed to the 'MiddlewarePipeline' service.
** 
** For example, in your 'AppModule' class:
** 
** pre>
**   @Contribute { serviceType=Middleware# }
**   static Void contributeMiddleware(OrderedConfig config) {
**     conf.addOrdered("AuthMiddleware", conf.autobuild(AuthMiddleware#), ["before: Routes"])
**   }
** <pre
** 
const mixin Middleware {

	** Return 'true' if you handled the request and no further request processing should be performed. 
	** Otherwise the request should be sent down the pipeline.
	abstract Bool service(MiddlewarePipeline pipeline) 

}
