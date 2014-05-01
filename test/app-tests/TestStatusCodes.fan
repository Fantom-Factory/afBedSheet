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
		verifyEq(client.resCode, 501, "$client.resCode - $client.resPhrase")		
	}

	Void test417() {
		client.reqUri = reqUri(`/statuscode/417`) 
		client.writeReq
		client.readRes
		verifyEq(client.resCode, 417, "$client.resCode "+ client.resPhrase)
	}
	
}
