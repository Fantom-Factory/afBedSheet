using web

internal class TestBedClient : BsTest {
	
	Void testUrisMustNotHaveAuth() {
		bs := BedServer(T_AppModule#).startup
		bc := bs.makeClient
		
		verifyErrTypeMsg(Err#, "URIs must NOT have an authority (scheme, host or port) - http://www.alienfactory.co.uk/dude") {
			bc.get(`http://www.alienfactory.co.uk/dude`)
		}

		bs.shutdown
	}
	
}
