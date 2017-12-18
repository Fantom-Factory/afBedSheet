
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
			"X-Forwarded-Host"	: "example.com:12",
		]
		verifyEq(getHost(headers), `https://example.com:12/`)
		
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
			
		headers = [ "host"	: "example.com" ]
		verifyEq(getHost(headers), `//example.com/`)

		headers = [ "host"	: "example.com:8080" ]
		verifyEq(getHost(headers), `//example.com:8080/`)

		headers = [ : ]
		verifyEq(getHost(headers), null)
		
		// real AWS example from StackHub - note the lack of 'X-Forwarded-Host' but a preserved 'host'
		headers = ["Referer":"http://stackhub.org/dude", "X-Forwarded-Proto":"http", "X-Forwarded-Port":"80", "X-Forwarded-For":"2a00:23c4:dc36:7f00:2c8b:ac02:4a99:dabf, 141.101.107.191", "host":"stackhub.org"]
		verifyEq(getHost(headers), `http://stackhub.org/`)	// note Uri will normalise port 80 for us - see echo(`http://stackhub.org:80/`) //--> http://stackhub.org/

		headers = ["X-Forwarded-Proto":"http", "X-Forwarded-Port":"8081", "X-Forwarded-For":"2a00:23c4:dc36:7f00:2c8b:ac02:4a99:dabf, 141.101.107.191", "host":"stackhub.org"]
		verifyEq(getHost(headers), `http://stackhub.org:8081/`)
	}
	
	Uri? getHost(Str:Str headers) {
		HttpRequestImpl.hostViaHeaders(headers)
	}
}
