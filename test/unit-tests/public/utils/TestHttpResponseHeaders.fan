
class TestHttpResponseHeaders : Test {
	
	Void testContentSecurityPolicy() {
		resMap  := Str:Str[:]
		headers := HttpResponseHeaders(resMap)
		
		verifyEq(headers.contentSecurityPolicy, null)
		
		resMap["Content-Security-Policy"] = "default-src"
		verifyEq(headers.contentSecurityPolicy["default-src"], "")

		resMap["Content-Security-Policy"] = "default-src 'self'"
		verifyEq(headers.contentSecurityPolicy["default-src"], "'self'")
		
		headers.contentSecurityPolicy = [
			"default-src": "'self'",
			"font-src"   : "'self' https://fonts.googleapis.com/",
			"object-src" :"'none'",
			"neep"       : ""
		]
		verifyEq(headers.contentSecurityPolicy["default-src"], "'self'")
		verifyEq(headers.contentSecurityPolicy["font-src"], "'self' https://fonts.googleapis.com/")
		verifyEq(headers.contentSecurityPolicy["object-src"], "'none'")
		verifyEq(headers.contentSecurityPolicy["neep"], "")
		
		headers.contentSecurityPolicy = null
		verifyEq(headers.contentSecurityPolicy, null)

		headers.contentSecurityPolicy = [:]
		verifyEq(headers.contentSecurityPolicy, null)
	}

	Void testAddCsp() {
		headers := HttpResponseHeaders(Str:Str[:])
		
		headers.addCsp("script-src", "val-1")
		verifyEq(headers.contentSecurityPolicy["script-src"], "val-1")

		headers.addCsp("script-src", "val-2")
		verifyEq(headers.contentSecurityPolicy["script-src"], "val-1 val-2")
	}
}
