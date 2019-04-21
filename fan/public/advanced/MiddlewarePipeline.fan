using afIoc
using afConcurrent::LocalRefManager

** (Service) - Contribute your 'Middleware' classes to this.
@NoDoc	// Don't overwhelm the masses!
const mixin MiddlewarePipeline {

	** The actual list of middleware used.
	abstract Middleware[] middleware()
	
	** Calls the next middleware in the pipeline.
	abstract Void service()
	
	** Logs the middlewere stack to 'info'.
	abstract Void logMiddleware()
}

internal const class MiddlewarePipelineImpl : MiddlewarePipeline {

	@Inject	 const Log				log
	@Inject	 const |->RequestState|	reqState
	@Inject	 const LocalRefManager?	localManager
	@Inject	 const HttpResponse?	httpResponse
	@Inject	 const HttpSession		httpSession
			 const Str:Middleware	middlewareMap
	
	new make(Str:Middleware middleware, |This| in) {
		in(this)
		this.middlewareMap = middleware
	}
	
	override Middleware[] middleware() {
		middlewareMap.vals
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
				httpSession._finalSession

				// this commits the response (by calling res.out) if it hasn't already
				// e.g. 304's and redirects have no body, so need to be committed here
				try httpResponse.out.flush.close
				// flushing a WebSocket upgrade causes: sys::Err: Must set Content-Length or Content-Type to write content
				// but the 'upgraded' flag is buried inside WispRes, to which we have no access, so just ignore for now
				catch { /* meh */ }
				
				localManager.cleanUpThread				
			}
		}
	}
	
	override Void logMiddleware() {
		buf := StrBuf()
		buf.add("\n\n")
		buf.add("BedSheet Middleware\n")
		buf.add("===================\n")
		maxSize := (Int) middlewareMap.keys.reduce(0) |Int max, key| { max.max(key.size) }
		middlewareMap.each |val, key| {
			buf.add(key).addChar(' ')
			buf.add("." * (maxSize - key.size)).add(" : ")
			buf.add(val.typeof.qname).addChar('\n')
		}
		log.info(buf.toStr)
	}
}
