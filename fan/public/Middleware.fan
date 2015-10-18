
** Implement to define BedSheet middleware. 
** 
** HTTP requests are funnelled through a stack of middleware instances until they reach a terminator. 
** The default BedSheet terminator returns a 404 error.
**  
** Middleware may perform processing before and / or after passing the request down the pipeline to 
** other middleware instances. Use middleware to address cross cutting concerns such as 
** authentication and authorisation. See the FantomFactory article 
** [Basic HTTP Authentication With BedSheet]`article:basic-http-authentication-with-bedSheet` for examples.
** 
** Because middleware effectively wrap other middleware instances and each can terminate the 
** pipeline prematurely, the ordering of middleware is extremely important. 
** 
** 'Route' instances are processed in the 'Routes' middleware. So generally you would explicitly 
** contribute your own middleware to be *before* or *after* this.
** 
** IoC Configuration
** =================
** Instances of 'Middleware' should be contributed to the 'MiddlewarePipeline' service.
** 
** For example, in your 'AppModule' class:
** 
** pre>
**   syntax: fantom 
**   @Contribute { serviceType=MiddlewarePipeline# }
**   Void contributeMiddleware(Configuration config) {
**       config.set("MyMiddleware", config.build(MyMiddleware#)).before("afBedSheet::Routes")
**   }
** <pre
// Used by Duvet
const mixin Middleware {

	** Call 'pipeline.service' to allow other Middleware to further process the request:
	** 
	** pre>
	** syntax: fantom
	** const class MyMiddleware : Middleware {
	**     override Void service(MiddlewarePipeline pipeline) {
	**         ...
	**         ...
	**         // pass the request to other middleware for processing
	**         pipeline.service 
	**         ...
	**         ...
	**     }
	** }
	** <pre 
	abstract Void service(MiddlewarePipeline pipeline) 

}
