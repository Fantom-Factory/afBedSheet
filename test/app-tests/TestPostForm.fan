using web::WebClient

internal class TestPostForm : AppTest {
	
	Void testStandardPost() {
		body := Uri.encodeQuery(["wot":"ever"])
		client.with {
			it.reqUri	 = this.reqUri(`/postForm`) 
			it.reqMethod = "POST"
			it.reqHeaders["Content-Type"] = "application/x-www-form-urlencoded"
			it.reqHeaders["Content-Length"] = body.size.toStr
			it.writeReq
			it.reqOut.print(body).close
			it.readRes
		}
		res := client.resIn.readAllStr.trim
		if (client.resCode != 200)
			fail("$client.resCode $client.resPhrase \n$res")
				
		verifyEq(res, ["wot":"ever"].toCode)
	}

	Void testPostWith100Continue() {
		// this is handled by WispReq
		body := Uri.encodeQuery(["wot":"ever"])
		client.with {
			it.reqUri	 = this.reqUri(`/postForm`) 
			it.reqMethod = "POST"
			it.reqHeaders["Content-Type"] = "application/x-www-form-urlencoded"
			it.reqHeaders["Content-Length"] = body.size.toStr
			it.reqHeaders["Expect"] = "100-continue"
			it.writeReq
			it.readRes
			if (client.resCode != 100)
				fail("Not 100-Continue :: $it.resCode-$it.resPhrase")
			it.reqOut.print(body).close
			it.readRes			
		}
		res := client.resIn.readAllStr.trim
		if (client.resCode != 200)
			fail("$client.resCode $client.resPhrase \n$res")
				
		verifyEq(res, ["wot":"ever"].toCode)
	}
}
