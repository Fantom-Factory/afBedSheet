
internal class TestHttpRequest : BsTest {

	Void testHostViaForwarded() {
		headers	 := [:]

		headers = [ "Forwarded"	: "for=192.0.2.43, for=198.51.100.17;by=203.0.113.60;proto=http;host=example.com" ]
		verifyEq(getHost(headers), `http://example.com/`)
		
		headers = [ "Forwarded"	: "for=192.0.2.43, for=198.51.100.17;by=203.0.113.60;proto=http;host=\"example.com\"" ]
		verifyEq(getHost(headers), `http://example.com/`)
		
		headers = [ "Forwarded"	: "for=192.0.2.43, for=198.51.100.17;by=203.0.113.60;host=\"example.com\"" ]
		verifyEq(getHost(headers), `//example.com/`)
		
		headers = [
			"X-Forwarded-Proto"	: "https",
			"X-Forwarded-Host"	: "example.com:8080"
		]
		verifyEq(getHost(headers), `https://example.com:8080/`)
		
		headers = [
			"X-Forwarded-Proto"	: "https",
			"X-Forwarded-Host"	: "example.com:",
			"X-Forwarded-Port"	: "8080"
		]
		verifyEq(getHost(headers), `https://example.com:8080/`)
		
		headers = [
			"X-Forwarded-Proto"	: "https",
			"X-Forwarded-Host"	: "example.com",
			"X-Forwarded-Port"	: "8080"
		]
		verifyEq(getHost(headers), `https://example.com:8080/`)
			
		headers = [
			"X-Forwarded-Host"	: "example.com",
			"X-Forwarded-Port"	: "8080"
		]
		verifyEq(getHost(headers), `//example.com:8080/`)
			
		headers = [
			"X-Forwarded-Host"	: "example.com",
		]
		verifyEq(getHost(headers), `//example.com/`)
			
		headers = [ "Host"	: "example.com" ]
		verifyEq(getHost(headers), `//example.com/`)

		headers = [ "Host"	: "example.com:8080" ]
		verifyEq(getHost(headers), `//example.com:8080/`)

		headers = [ : ]
		verifyEq(getHost(headers), null)
	}
	
	Uri? getHost(Str:Str headers) {
		HttpRequestImpl.hostViaHeaders(headers)
	}
}
