
class TestHttpResponseHeaders : Test {
	
	Void testContentSecurityPolicy() {
		resMap  := Str:Str[:]
		resFn   := Unsafe(|->Obj| { resMap })
		httpRes := HttpResponseHeaders(|->Obj| { resFn.val->call }, |->| { })
		
		verifyEq(httpRes.contentSecurityPolicy, null)
		
		resMap["Content-Security-Policy"] = "default-src"
		verifyEq(httpRes.contentSecurityPolicy["default-src"], "")

		resMap["Content-Security-Policy"] = "default-src 'self'"
		verifyEq(httpRes.contentSecurityPolicy["default-src"], "'self'")
		
		httpRes.contentSecurityPolicy = [
			"default-src": "'self'",
			"font-src"   : "'self' https://fonts.googleapis.com/",
			"object-src" :"'none'",
			"neep"       : ""
		]
		verifyEq(httpRes.contentSecurityPolicy["default-src"], "'self'")
		verifyEq(httpRes.contentSecurityPolicy["font-src"], "'self' https://fonts.googleapis.com/")
		verifyEq(httpRes.contentSecurityPolicy["object-src"], "'none'")
		verifyEq(httpRes.contentSecurityPolicy["neep"], "")
	}
}
