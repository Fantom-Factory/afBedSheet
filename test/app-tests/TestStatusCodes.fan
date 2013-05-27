using web::WebClient

internal class TestStatusCodes : AppTest {
	
	Void test404() {
		verify404(`/e-r-r-o-r-4-0-4`)
		client = WebClient()
		verify404(`/statuscode/404`)
		verify404(`/favicon.ico`)
		verify404(`/robots.txt`)
	}

	Void test417() {
		client.reqUri = reqUri(`/statuscode/417`) 
		client.writeReq
		client.readRes
		verifyEq(client.resCode, 417, client.resPhrase)
	}
	
}
