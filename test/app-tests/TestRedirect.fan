using web::WebClient

internal class TestRedirect : AppTest {
	
	Void testHttp10MovedPerm() {
		client.reqVersion = Version("1.0")
		client.followRedirects = false
		client.reqUri = reqUri(`/redirect/movedPerm`)
		client.writeReq
		client.readRes
		verifyEq(client.resCode, 301, "$client.resCode "+ client.resPhrase)
		verifyEq(client.resHeaders["Location"], "/movedPermanently")
	}

	Void testHttp10MovedTemp() {
		client.reqVersion = Version("1.0")
		client.followRedirects = false
		client.reqUri = reqUri(`/redirect/movedTemp`)
		client.writeReq
		client.readRes
		verifyEq(client.resCode, 302, "$client.resCode "+ client.resPhrase)
		verifyEq(client.resHeaders["Location"], "/movedTemporarily")
	}

	Void testHttp10AfterPost() {
		client.reqVersion = Version("1.0")
		client.followRedirects = false
		client.reqUri = reqUri(`/redirect/afterPost`)
		client.writeReq
		client.readRes
		verifyEq(client.resCode, 302, "$client.resCode "+ client.resPhrase)
		verifyEq(client.resHeaders["Location"], "/afterPost")
	}

	Void testHttp11MovedPerm() {
		client.reqVersion = Version("1.1")
		client.followRedirects = false
		client.reqUri = reqUri(`/redirect/movedPerm`)
		client.writeReq
		client.readRes
//		verifyEq(client.resCode, 308, "$client.resCode "+ client.resPhrase)
		verifyEq(client.resCode, 301, "$client.resCode "+ client.resPhrase)
		verifyEq(client.resHeaders["Location"], "/movedPermanently")
	}

	Void testHttp11MovedTemp() {
		client.reqVersion = Version("1.1")
		client.followRedirects = false
		client.reqUri = reqUri(`/redirect/movedTemp`)
		client.writeReq
		client.readRes
		verifyEq(client.resCode, 307, "$client.resCode "+ client.resPhrase)
		verifyEq(client.resHeaders["Location"], "/movedTemporarily")
	}

	Void testHttp11AfterPost() {
		client.reqVersion = Version("1.1")
		client.followRedirects = false
		client.reqUri = reqUri(`/redirect/afterPost`)
		client.writeReq
		client.readRes
		verifyEq(client.resCode, 303, "$client.resCode "+ client.resPhrase)
		verifyEq(client.resHeaders["Location"], "/afterPost")
	}
}
