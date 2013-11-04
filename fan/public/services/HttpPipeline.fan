
** (Service) - The HTTP Pipeline that 'HttpPipelineFilters' should be contributed to. The terminator 
** at the end of the pipeline is the default routing service.
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

	abstract Bool service() 

}

** A filter for HTTP requests.
const mixin HttpPipelineFilter {

	** Return 'true' if the this filter handled the request
	abstract Bool service(HttpPipeline handler) 

}
