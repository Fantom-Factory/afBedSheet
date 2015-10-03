
internal class TestBuff : AppTest {

	Void testBuffering() {
		getAsStr(`/buff/buff`)
		verifyEq(client.resHeaders["Content-Length"], 	"13")
		verifyEq(client.resCode, 200)
	}

	Void testDisableBuffering() {
		client.reqUri = reqUri(`/buff/nobuff`)
		// WISP only sets the transfer-Encoding for persistent connections
		client.reqHeaders["Connection"] = "keep-alive"
		client.writeReq
		client.readRes

		echo(client.resHeaders)
		verifyEq(client.resHeaders["Transfer-Encoding"], "chunked")
		verifyFalse(client.resHeaders.containsKey("Content-Length"), "chunked")
		verifyEq(client.resCode, 200)
	}
}
