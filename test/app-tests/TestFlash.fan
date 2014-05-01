using web::WebClient

internal class TestFlash : AppTest {
	
	Void testFlash() {
		verifyEq(getAsStr(`/saveFlashMsg/Blonde`), "Msg = null")
		cookie 		:= client.resHeaders["Set-Cookie"].replace(";Path=/", "")
		
		client = WebClient()
		client.reqHeaders["Cookie"] = cookie
		verifyEq(getAsStr(`/saveFlashMsg/Brunette`), "Msg = Blonde")
		
		client = WebClient()
		client.reqHeaders["Cookie"] = cookie
		verifyEq(getAsStr(`/showFlashMsg`), "Msg = Brunette")

		client = WebClient()
		verifyEq(getAsStr(`/showFlashMsg`), "Msg = null")
	}
}
