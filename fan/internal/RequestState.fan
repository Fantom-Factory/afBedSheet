using afIoc
using web

** Mutable request data
internal class RequestState {	
	@Inject	WebReq?					webReq		// nullable for testing
	@Inject	WebRes?					webRes		// nullable for testing
	@Inject	HttpOutStreamBuilder?	outStreamBuilder
			Duration				startTime		:= Duration.now
			Int 					middlewareDepth	:= 0
			Bool?					disableGzip
			Bool?					disableBuffering
			[Str:Obj?]?				flashMapOld
			[Str:Obj?]?				flashMapNew
	private HttpRequestBody?		requestBodyRef
	private [Str:Str]?				responseHeadersRef
	private OutStream?				outStreamRef
	
	new make(|This|? in) { in?.call(this) }
	
	OutStream out() {
		if (outStreamRef == null)
			outStreamRef = outStreamBuilder.build
		return outStreamRef
	}
	
	HttpRequestBody requestBody() {
		if (requestBodyRef == null)
			requestBodyRef = HttpRequestBody(webReq)
		return requestBodyRef
	}

	Str:Str responseHeaders() {
		if (responseHeadersRef == null)
			responseHeadersRef = webRes.headers
		return responseHeadersRef
	}
}
