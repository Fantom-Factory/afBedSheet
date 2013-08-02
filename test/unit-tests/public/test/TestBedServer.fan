using web

internal class TestBedServer : BsTest {
	
	Void testBasics() {
		bs := BedServer(T_AppModule#).startup
		bc := bs.makeClient

		res := bc.get(`/textResult/plain`)
		verifyEq(res.asStr, "This is plain text")
		verifyEq(res.statusCode, 200)
	}

	Void testSession() {
		bs := BedServer(T_AppModule#).startup
		bc := bs.makeClient

		verifyEq(bc.get(`/textResult/plain`).asStr, "This is plain text")
		verifyNull(bc.session)
		
		verifyEq(bc.get(`/session`).asStr, "count 1")
		verifyNotNull(bc.session)
		
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
