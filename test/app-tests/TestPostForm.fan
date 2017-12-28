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

	Void testMultipartPost() {
		// bug-fix - make sure multipart forms can be read more than once
		body := 
"--Boundary-XXXX\r
 Content-Disposition: form-data; name=\"wot2\"\r
 Content-Type: text/plain; charset=utf-8\r
 \r
 ever2\r
 --Boundary-XXXX--\r\n"
		client.with {
			it.reqUri	 = this.reqUri(`/postMultipartForm`) 
			it.reqMethod = "POST"
			it.reqHeaders["Content-Type"]	= "multipart/form-data;boundary=Boundary-XXXX"
			it.reqHeaders["Content-Length"]	= body.size.toStr
			it.writeReq
			it.reqOut.print(body).close
			it.readRes
		}
		res := client.resIn.readAllStr.trim
		if (client.resCode != 200)
			fail("$client.resCode $client.resPhrase \n$res")

		verifyEq(res, [:].add("wot2","ever2").toCode)
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
