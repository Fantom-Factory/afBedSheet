
// FIXME: fandoc
** Implement to define a HTTP Pipeline Filter. Contribute it to the `HttpPipeline` service.
** 
** pre>
**   @Contribute { serviceType=HttpPipeline# }
**   static Void contributeHttpPipeline(OrderedConfig conf) {
**     conf.addOrdered("HttpRequestLogFilter", conf.autobuild(HttpRequestLogFilter#))
**   }
** <pre
** 
** Use filters to address cross cutting concerns such as authorisation.
//const mixin HttpPipelineFilter {
const mixin Middleware {

	** Return 'true' if you handled the request and no further request processing should be performed. 
	** Otherwise the request should be sent down the pipeline.
	abstract Bool service(MiddlewarePipeline pipeline) 

}
