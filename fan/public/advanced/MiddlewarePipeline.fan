using afIoc3

** (Service) - Contribute your 'Middleware' classes to this.
@NoDoc	// Don't overwhelm the masses!
const mixin MiddlewarePipeline {

	** Calls the next middleware in the pipeline.
	abstract Void service() 
}

internal const class MiddlewarePipelineImpl : MiddlewarePipeline {

	@Inject
	const |->RequestState|	reqState
	const Middleware[]		middleware
	
	new make(Middleware[] middleware, |This| in) {
		in(this)
		this.middleware = middleware
	}
	
	** Calls the next middleware in the pipeline.
	override Void service() {
		reqState := reqState()
		reqState.middlewareDepth++
		try {
			middleware.getSafe(reqState.middlewareDepth - 1)?.service(this)
		} finally {
			reqState.middlewareDepth--
		}
	}
}
