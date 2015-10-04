using afIoc3

** (Service) - Contribute your 'Middleware' classes to this.
@NoDoc	// Don't overwhelm the masses!
const mixin MiddlewarePipeline {

	** Calls the next middleware in the pipeline.
	abstract Void service() 
}

internal const class MiddlewarePipelineImpl : MiddlewarePipeline {

	@Inject const |->RequestState|		reqState
	@Inject	const ThreadLocalManager?	localManager
	@Inject	const HttpResponse?			httpResponse
			const Middleware[]			middleware
	
	new make(Middleware[] middleware, |This| in) {
		in(this)
		this.middleware = middleware
	}
	
	override Void service() {
		reqState := reqState()
		reqState.middlewareDepth++

		try {
			middleware.getSafe(reqState.middlewareDepth - 1)?.service(this)

		} finally {
			reqState.middlewareDepth--
			
			// clean up - don't wish to pollute stacktraces with yet moar middleware just for this 
			if (reqState.middlewareDepth == 0) {
				// this commits the response (by calling res.out) if it hasn't already
				// e.g. 304's and redirects have no body, so need to be committed here
				httpResponse.out.close
				
				localManager.cleanUpThread				
			}
		}
	}
}
