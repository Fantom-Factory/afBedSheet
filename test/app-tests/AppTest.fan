using web::WebClient
using wisp::WispService

internal class AppTest : Test {
	
	private Int				port	:= 8079 
	private Str				modName	:= AppModule#.qname
	private WispService? 	willow
			WebClient	 	client	:= WebClient()
	
	override Void setup() {
		mod 	:= BedSheetWebMod(modName, port, [:])
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
		client = WebClient()
	}
	
	Uri reqUri(Uri uri) {
		"http://localhost:$port".toUri + uri
	}
}
