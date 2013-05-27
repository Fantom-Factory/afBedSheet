using web::WebClient
using wisp::WispService

internal class AppTest : Test {
	
	private Int				port	:= 8079 
	private Str				modName	:= AppModule#.qname
	private WispService? 	willow
			WebClient	 	client	:= WebClient()
	
	override Void setup() {
		mod 	:= BedSheetWebMod(modName)
		willow 	:= WispService { it.port=this.port; it.root=mod }
		willow.start
	}
	
	override Void teardown() {
		willow?.uninstall
	}

	Str getAsStr(Uri uri, Str method := "GET") {
		client.reqUri = `http://localhost:$port` + uri
		client.reqMethod = method
		client.writeReq
		client.readRes
		res := client.resIn.readAllStr.trim
		if (client.resCode != 200)
			fail("$client.resCode $client.resPhrase \n$res")
		return res
	}
	
}
