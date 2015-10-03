using concurrent
using web

internal class RequestState {	
			WebReq 				webReq
			WebRes 				webRes
			Duration			startTime		:= Duration.now
			Int 				middlewareDepth	:= 0
			Bool?				disableGzip
			Bool?				disableBuffering
			[Str:Obj?]?			flashMapOld
			[Str:Obj?]?			flashMapNew
	private HttpRequestBody?	requestBodyRef
	private [Str:Str]?			responseHeadersRef
	
	new make() {
		try {
			webReq = Actor.locals["web.req"]
			webRes = Actor.locals["web.res"]
		} catch (NullErr e) 
			throw Err("No web request active in thread")
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
