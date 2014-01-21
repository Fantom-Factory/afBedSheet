
** (Service) - Contribute your 'HttpPipelineFilter' classes to this.
//const mixin HttpPipeline {
@NoDoc	// don't overwhelm the masses!
const mixin MiddlewarePipeline {

	** Calls the next middleware in the pipeline. Returns 'true' if the pipeline handled the request.
	abstract Bool service() 
}
