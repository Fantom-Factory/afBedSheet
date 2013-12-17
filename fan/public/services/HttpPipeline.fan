
** (Service) - Contribute your 'HttpPipelineFilter' classes to this.
**
** Example:
** 
** pre>
**   @Contribute { serviceType=HttpPipeline# }
**   static Void contributeHttpPipeline(OrderedConfig conf) {
** 
**     conf.addOrdered("HttpRequestLogFilter", conf.autobuild(HttpRequestLogFilter#), ["after: BedSheetFilters"])
** 
**   }
** 
** <pre
const mixin HttpPipeline {

	** Calls the next filter in the pipeline. Returns 'true' if the pipeline handled the request.
	abstract Bool service() 

}

** Implement to define a HTTP Pipeline Filter. Contribute it to the `HttpPipeline` service.
** 
** Use filters to address cross cutting concerns such as authorisation.
const mixin HttpPipelineFilter {

	** Return 'true' if the this filter handled the request and no further request processing should be performed.
	abstract Bool service(HttpPipeline handler) 

}
