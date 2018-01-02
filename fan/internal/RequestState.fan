using afIoc
using web

** Mutable request data
internal class RequestState {	
	@Inject	WebReq?					webReq				// nullable for testing
	@Inject	WebRes?					webRes				// nullable for testing
	@Inject	HttpOutStreamBuilder?	outStreamBuilder	// nullable for testing
			Duration				startTime		:= Duration.now
			Int 					middlewareDepth	:= 0
			Bool?					disableGzip
			Bool?					disableBuffering
			[Str:Obj?]?				flashMapOld
			[Str:Obj?]?				flashMapNew
			[Str:Obj?]?				mutableSessionState {
				get { if (&mutableSessionState == null) &mutableSessionState = Str:Obj?[:]; return &mutableSessionState }
			}
			HttpRequestHeaders		requestHeaders
			HttpResponseHeaders		responseHeaders
	private HttpRequestBody?		_requestBody
	private OutStream?				_responseBody
	
	new make(|This|? in) {
		in?.call(this)
		// cache the headers so we can access / read them after the response has been committed - handy for logging
		// note this only works while 'webRes.headers' returns the actual map used, and not a copy
		requestHeaders  = HttpRequestHeaders (webReq.headers)
		responseHeaders = HttpResponseHeaders(webRes.headers, |->| {
			if (webRes.isCommitted)
				throw Err("HTTP Response has already been committed")				
		})
	}
	
	HttpRequestBody requestBody() {
		if (_requestBody == null)
			_requestBody = HttpRequestBody(webReq)
		return _requestBody
	}
	
	OutStream responseBody() {
		if (_responseBody == null)
			_responseBody = outStreamBuilder.build
		return _responseBody
	}
}
