using web::WebClient

internal class TestOnCommit : AppTest {
	
	Void testPlain() {
		res := getAsStr(`/onCommit`)
		verifyEq(res, "Okay")
		verifyEq(client.resHeaders["X-special"], "Judge Dredd")
	}

}
