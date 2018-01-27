using web::WebClient

internal class TestSession : AppTest {

	Void testSession() {
		verifyEq(getAsStr(`/session`), "count 1 - created true")
		cookie 		:= client.resHeaders["Set-Cookie"].replace(";Path=/", "")

		client = WebClient()
		client.reqHeaders["Cookie"] = cookie
		verifyEq(getAsStr(`/session`), "count 2 - created false")
		
		client = WebClient()
		client.reqHeaders["Cookie"] = cookie
		verifyEq(getAsStr(`/session`), "count 3 - created false")

		client = WebClient()
		verifyEq(getAsStr(`/session`), "count 1 - created true")

		client = WebClient()
		verifyEq(getAsStr(`/sessionDelete`), "session exists = false")
		
		
		// test session.onCreate() is still fired when an old, timed out session ID is passed in
		// this tests the "afBedSheet.exists" logic
		client = WebClient()
		client.reqHeaders["Cookie"] = "fanws=xxxx;HttpOnly"
		verifyEq(getAsStr(`/session`), "count 1 - created true")
		
		// this validates the fact that wisp has session fixation
		newCookie := client.resHeaders["Set-Cookie"]
		verifyNull(newCookie)
	}

	Void testImmutableSessionVals() {
		client.reqUri = reqUri(`/sessionImmutable1?v=dredd`)
		client.writeReq
		client.readRes
		verifyEq(client.resCode, 200)

		cookie := client.resHeaders["Set-Cookie"].replace(";Path=/", "")
		client = WebClient()
		client.reqHeaders["Cookie"] = cookie
		verifyEq(getAsStr(`/sessionImmutable2`), "dredd")
	}

	Void testSerialisableSessionVals() {
		client.reqUri = reqUri(`/sessionSerialisable1?v=anderson`)
		client.writeReq
		client.readRes
		verifyEq(client.resCode, 200)

		cookie := client.resHeaders["Set-Cookie"].replace(";Path=/", "")
		client = WebClient()
		client.reqHeaders["Cookie"] = cookie
		verifyEq(getAsStr(`/sessionSerialisable2`), "anderson")
	}

	Void testMutableSessionVals() {
		client.reqUri = reqUri(`/sessionMutable1?v=death`)
		client.writeReq
		client.readRes
		verifyEq(client.resCode, 200)

		cookie := client.resHeaders["Set-Cookie"].replace(";Path=/", "")
		client = WebClient()
		client.reqHeaders["Cookie"] = cookie
		verifyEq(getAsStr(`/sessionMutable2?v=dredd`), "death")

		client = WebClient()
		client.reqHeaders["Cookie"] = cookie
		verifyEq(getAsStr(`/sessionMutable3`), "dredd")
	}

	Void testBadSessionVals() {
		client.reqUri = reqUri(`/sessionBad`)
		client.writeReq
		client.readRes

		// ensure dodgy session values are caught *before* the response is sent to the client
		verifyEq(client.resCode, 500)
	}
}
