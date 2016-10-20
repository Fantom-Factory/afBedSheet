using web::WebClient
using xml::XParser

internal class TestStatusCodes : AppTest {
	
	Void test404() {
		verify404(`/e-r-r-o-r-4-0-4`)
		
		client = WebClient()
		verify404(`/statuscode/404`)
		
		client = WebClient()
		verify404(`/favicon.ico`)
		
		client = WebClient()
		verify404(`/robots.txt`)
	}
	
	** Test we get 501 for weird HTTP methods
	Void test501() {
		client = WebClient()
		client.reqUri = reqUri(`/robots.txt`)
		client.reqMethod = "DELETE"
		client.writeReq
		client.readRes
		resStr := client.resIn.readAllStr
		verifyEq(client.resCode, 501, "$client.resCode - $client.resPhrase")
		verifyEq(client.resHeaders["Content-Length"], "44")
		verifyEq(resStr.size > 0, true)
		
		// test that a HEAD requests still don't return content
		// The HEAD method is identical to GET except that the server MUST NOT return a message-body in the response. 
		// https://www.w3.org/Protocols/rfc2616/rfc2616-sec9.html#sec9.4
		
		client = WebClient()
		client.reqUri = reqUri(`/robots.txt`)
		client.reqMethod = "HEAD"
		client.writeReq
		client.readRes
		resStr = client.resIn.readAllStr
		verifyEq(client.resCode, 501, "$client.resCode - $client.resPhrase")
		verifyEq(client.resHeaders["Content-Length"], "42")
		verifyEq(resStr.size, 0)
	}

	Void test417() {
		client.reqUri = reqUri(`/statuscode/417`) 
		client.writeReq
		client.readRes
		client.resIn.readAllBuf	// drain the stream to prevent errs on the server
		verifyEq(client.resCode, 417, "$client.resCode "+ client.resPhrase)
	}
	
	Void testHtmlOnlyReturnedIfWanted() {
		
		// test we default to text/plain if no accept header is sent
		client.reqHeaders["Accept"] = "<no-accept>"
		verify404(`/e-r-r-o-r-4-0-4`)
		verifyEq(MimeType(client.resHeaders["Content-Type"]).noParams.toStr, "text/plain")
		verify  (client.resStr.size > 0)
		
		// test XHTML
		client = WebClient()
		client.reqHeaders["Accept"] = "application/*"
		verify404(`/e-r-r-o-r-4-0-4`)
		verifyEq(MimeType(client.resHeaders["Content-Type"]).noParams.toStr, "application/xhtml+xml")
		XParser(client.resStr.in).parseDoc

		// test text/html
		client = WebClient()
		client.reqHeaders["Accept"] = "text/html"
		verify404(`/e-r-r-o-r-4-0-4`)
		verifyEq(MimeType(client.resHeaders["Content-Type"]).noParams.toStr, "text/html")
		verifyEq(client.resStr.startsWith("<!DOCTYPE html>\n"), true)

		// test text/plain
		client = WebClient()
		client.reqHeaders["Accept"] = "text/plain"
		verify404(`/e-r-r-o-r-4-0-4`)
		verifyEq(MimeType(client.resHeaders["Content-Type"]).noParams.toStr, "text/plain")
		verifyEq(client.resStr, "404 - Route `/e-r-r-o-r-4-0-4` not found (GET)")

		// test no match
		client = WebClient()
		client.reqHeaders["Accept"] = "anything/else"
		verify404(`/e-r-r-o-r-4-0-4`)
		verifyFalse(client.resHeaders.containsKey("Content-Type"))
		verifyEq(client.resStr.size, 0)
	}
}
