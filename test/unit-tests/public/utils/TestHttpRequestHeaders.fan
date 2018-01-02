
class TestHttpRequestHeaders : Test {
	
	Void testDodgyIfModifiedDoesNotThrowErr() {
		httpReq := HttpRequestHeaders(["If-Modified-Since":"oops"])
		verifyNull(httpReq.ifModifiedSince)
	}
}
