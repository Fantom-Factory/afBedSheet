using web::WebClient
using wisp::WispService

internal class AppTest : Test {
	
	private Int				port	:= 8079 
	private WispService? 	willow
			WebClient	 	client	:= WebClient()

	override Void setup() {
		mod 	:= BedSheetWebMod(iocModules[0].qname, port, ["iocModules":iocModules])
		willow 	= WispService { it.port=this.port; it.root=mod }
		willow.start
	}

	override Void teardown() {
		willow?.uninstall
	}

	Str getAsStr(Uri uri, Str method := "GET") {
		client.reqUri = reqUri(uri) 
		client.reqMethod = method
		client.writeReq
		client.readRes
		res := client.resIn.readAllStr.trim
		if (client.resCode != 200)
			fail("$client.resCode $client.resPhrase \n$res")
		return res
	}

	Void verify404(Uri uri) {
		verifyStatus(uri, 404)
	}
	
	Void verifyStatus(Uri uri, Int status) {
		client.reqUri = reqUri(uri) 
		client.writeReq
		client.readRes
		verifyEq(client.resCode, status, client.resPhrase)
	}
	
	Void verifyLastModified(DateTime lastModified) {
		clientDate := DateTime.fromHttpStr(client.resHeaders["Last-Modified"]).toTimeZone(TimeZone.utc)
		verifyEq(clientDate, lastModified)		
	}
	
	Void verifyErrMsg(Type errType, Str errMsg, |Obj| func) {
		try {
			func(4)
		} catch (Err e) {
			if (!e.typeof.fits(errType)) 
				throw Err("Expected $errType got $e.typeof", e)
			msg := e.msg
			if (msg != errMsg)
				verifyEq(errMsg, msg)	// this gives the Str comparator in eclipse
			return
		}
		throw Err("$errType not thrown")
	}
	Uri reqUri(Uri uri) {
		"http://localhost:$port".toUri + uri
	}
	
	virtual Type[] iocModules() { [T_AppModule#] }
}
