using web

internal class TestBedServer : BsTest {
	
	Void testBedServer() {
		bs := BedServer(T_AppModule#).startup

		bc := bs.makeClient

		verifyEq(bc.get(`/session`).asStr, "count 1")
		verifyEq(bc.get(`/session`).asStr, "count 2")
		verifyEq(bc.get(`/session`).asStr, "count 3")
		
		bc = bs.makeClient
		verifyEq(bc.get(`/session`).asStr, "count 1")
				
		bs.shutdown
		
//		wc:=WebClient()
//		wc.reqUri = `http://localhost:8079/boom`
//		wc.getIn
	}
	
}
