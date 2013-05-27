using web::WebClient

internal class TestTextResult : AppTest {
	
	Void testPlain() {
		res := getAsStr(`/textResult/plain`)
		verifyEq(res.trim, "This is plain text")
		verifyEq(client.resHeaders["Content-Type"], "text/plain; charset=utf-8")
	}

	Void testHtml() {
		res := getAsStr(`/textResult/html`)
		verifyEq(res.trim, "This is html text <honest!/>")
		verifyEq(client.resHeaders["Content-Type"], "text/html; charset=utf-8")
	}

	Void testXml() {
		res := getAsStr(`/textResult/xml`)
		verifyEq(res.trim, "This is xml text <honest!/>")
		verifyEq(client.resHeaders["Content-Type"], "text/xml; charset=utf-8")
	}
	
}
