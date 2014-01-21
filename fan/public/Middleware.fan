
// FIXME: fandoc
** Implement to define BedSheet middleware. 
** 
** Contribute it to the `HttpPipeline` service.
** 
** Use middleware to address cross cutting concerns such as authorisation.
** 
** pre>
**   @Contribute { serviceType=HttpPipeline# }
**   static Void contributeHttpPipeline(OrderedConfig conf) {
**     conf.addOrdered("AuthMiddleware", conf.autobuild(AuthMiddleware#), ["before: Routes"])
**   }
** <pre
** 
const mixin Middleware {

	** Return 'true' if you handled the request and no further request processing should be performed. 
	** Otherwise the request should be sent down the pipeline.
	abstract Bool service(MiddlewarePipeline pipeline) 

}
