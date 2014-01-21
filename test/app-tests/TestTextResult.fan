using web::WebClient

internal class TestTextResult : AppTest {
	
	Void testPlain() {
		res := getAsStr(`/textResult/plain`)
		verifyEq(res, "This is plain text")
		verifyEq(client.resHeaders["Content-Type"], "text/plain; charset=UTF-8")
	}

	Void testHtml() {
		res := getAsStr(`/textResult/html`)
		verifyEq(res, "This is html text <honest!/>")
		verifyEq(client.resHeaders["Content-Type"], "text/html; charset=UTF-8")
	}

	Void testXml() {
		res := getAsStr(`/textResult/xml`)
		verifyEq(res, "This is xml text <honest!/>")
		verifyEq(client.resHeaders["Content-Type"], "application/xml; charset=UTF-8")
	}
	
}
