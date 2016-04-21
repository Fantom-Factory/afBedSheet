using web::WebClient

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
	
	Void test501() {
		// test we get 501 for weird HTTP methods
		client = WebClient()
		client.reqUri = reqUri(`/robots.txt`)
		client.reqMethod = "DELETE"
		client.writeReq
		client.readRes
		client.resIn.readAllBuf	// drain the stream to prevent errs on the server
		verifyEq(client.resCode, 501, "$client.resCode - $client.resPhrase")		
	}

	Void test417() {
		client.reqUri = reqUri(`/statuscode/417`) 
		client.writeReq
		client.readRes
		client.resIn.readAllBuf	// drain the stream to prevent errs on the server
		verifyEq(client.resCode, 417, "$client.resCode "+ client.resPhrase)
	}
	
	Void testHtmlOnlyReturnedIfWanted() {
		verify404(`/e-r-r-o-r-4-0-4`)
		verifyEq(MimeType(client.resHeaders["Content-Type"]).noParams.toStr, "application/xhtml+xml")
		verify  (client.resStr.size > 0)
		
		client = WebClient()
		client.reqHeaders["Accept"] = "application/*; q=0"
		verify404(`/e-r-r-o-r-4-0-4`)
		verifyFalse(client.resHeaders.containsKey("Content-Type"))
		verifyFalse(client.resStr.size > 0)

		client = WebClient()
		client.reqHeaders["Accept"] = "text/*; q=0.1"
		verify404(`/e-r-r-o-r-4-0-4`)
		verifyEq(MimeType(client.resHeaders["Content-Type"]).noParams.toStr, "text/plain")
		verifyEq(client.resStr, "404 - Route `/e-r-r-o-r-4-0-4` not found (GET)")
	}
}
