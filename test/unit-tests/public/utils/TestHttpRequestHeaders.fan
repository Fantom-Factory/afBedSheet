
class TestHttpRequestHeaders : Test {
	
	Void testDodgyIfModifiedDoesNotThrowErr() {
		httpReq := HttpRequestHeaders() |->Obj| { ["If-Modified-Since":"oops"] }
		verifyNull(httpReq.ifModifiedSince)
	}
}
