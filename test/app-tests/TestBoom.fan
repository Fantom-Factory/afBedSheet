
internal class TestBoom : AppTest {

	Void testBoomPage() {
		client.reqUri = reqUri(`/boom`)
		client.writeReq
		client.readRes
		
		// just check the status for now
		verifyEq(client.resCode, 500)
	}
	
}
