
** (Service) - Contribute your 'Middleware' classes to this.
@NoDoc	// don't overwhelm the masses!
const mixin MiddlewarePipeline {

	** Calls the next middleware in the pipeline.
	abstract Void service() 
}
