using web::WebClient

internal class TestSession : AppTest {
	
	Void testSession() {
		verifyEq(getAsStr(`/session`), "count 1")
		cookie 		:= client.resHeaders["Set-Cookie"].replace(";Path=/", "")
		
		client = WebClient()
		client.reqHeaders["Cookie"] = cookie
		verifyEq(getAsStr(`/session`), "count 2")
		
		client = WebClient()
		client.reqHeaders["Cookie"] = cookie
		verifyEq(getAsStr(`/session`), "count 3")

		client = WebClient()
		verifyEq(getAsStr(`/session`), "count 1")
	}
}
