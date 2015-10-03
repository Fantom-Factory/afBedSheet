using web::WebClient
using wisp::WispService
using afIocConfig::ConfigModule
using afIoc3::Registry

internal class AppTest : Test {
	
	private Int				port	:= 8079 
	private WispService? 	willow
			WebClient	 	client	:= WebClient()
			Registry?		registry

	override Void setup() {
		Log.get("web").level 		= LogLevel.warn
		Log.get("afIoc").level 		= LogLevel.warn
		Log.get("afIoc3").level 	= LogLevel.warn
		Log.get("afIocEnv").level 	= LogLevel.warn
		Log.get("afBedSheet").level = LogLevel.warn
		
		client.reqHeaders.clear

		bob := BedSheetBuilder(iocModules[0].qname)
			.addModules(iocModules)
			.addModule(ConfigModule#)
		mod := BedSheetBootMod(bob)
		willow 	= WispService { it.httpPort=this.port; it.root=mod }
		willow.start
		
		registry = mod.webMod->registry
	}

	override Void teardown() {
		// drain the stream to prevent errs on the server
		try { client.resIn.readAllBuf } catch {}
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

	Buf getAsBuf(Uri uri, Str method := "GET") {
		client.reqUri = reqUri(uri) 
		client.reqMethod = method
		client.writeReq
		client.readRes
		res := client.resIn.readAllBuf
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
		verifyEq(client.resCode, status, "$client.resCode - $client.resPhrase")
	}
	
	Void verifyLastModified(DateTime lastModified) {
		clientDate := DateTime.fromHttpStr(client.resHeaders["Last-Modified"]).toUtc
		verifyEq(clientDate, lastModified.floor(1sec).toUtc)		
	}
	
	Uri reqUri(Uri uri) {
		"http://localhost:$port".toUri + uri
	}
	
	virtual Type[] iocModules() { [T_AppModule#] }
}
