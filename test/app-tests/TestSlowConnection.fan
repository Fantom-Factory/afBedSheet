using web::WebClient

internal class TestSlowConnection : AppTest {
	
	Void testSlow() {
//		concurrent::Actor.sleep(1200sec)
		client.reqUri = reqUri(`/slow`) 
		client.writeReq
		client.readRes

		client.resIn.readChar
		client.resIn.readChar
		client.resIn.close
		
		// I was hoping this would cause a socket err on the server side - but, sigh, no...
	}	
}
