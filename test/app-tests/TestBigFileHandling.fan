using web::WebClient
using afIoc

** FileResponseProcessor sets the Content_Length, need to make sure it gets overwritten properly
internal class TestBigFileHandling : AppTest {
	
	override Type[] iocModules	:= [T_AppModule#]
	override Void setup() { }
	
	Void testHeadersForBigFilesNoBuff() {
		iocModules	:= [T_AppModule#]
		super.setup
		
		// no buff, no gzip
		client.reqHeaders["Accept-encoding"] = "gzip"
		getAsBuf(`/res/DeeDee.jpg`)
		verifyEq(client.resHeaders["Content-Encoding"], null)
		verifyEq(client.resHeaders["Content-Length"], 	"11868")
		
		// no buff, WITH gzip
		client = WebClient()
		client.reqHeaders["Accept-encoding"] = "gzip"
		getAsBuf(`/res/DeeDee.css`)
		verifyEq(client.resHeaders["Content-Encoding"], "gzip")
		verifyEq(client.resHeaders["Content-Length"], 	null)	
	}
	
	Void testHeadersForBigFilesBigBuff() {
		iocModules	= [T_AppModule#, T_TestBigFileHandlingBigBuffMod#]
		super.setup
		
		// bufferedOut, no gzip
		client.reqHeaders["Accept-encoding"] = "gzip"
		getAsBuf(`/res/DeeDee.jpg`)
		verifyEq(client.resHeaders["Content-Encoding"], null)
		verifyEq(client.resHeaders["Content-Length"], 	"11868")
		
		// bufferedOut, WITH gzip
		client = WebClient()
		client.reqHeaders["Accept-encoding"] = "gzip"
		getAsBuf(`/res/DeeDee.css`)
		verifyEq(client.resHeaders["Content-Encoding"], "gzip")
		verifyEq(client.resHeaders["Content-Length"], 	"11839")	
	}
}

internal class T_TestBigFileHandlingBigBuffMod {
	@Contribute { serviceType=ApplicationDefaults# } 
	static Void contributeApplicationDefaults(MappedConfig conf) {
		conf.setOverride(ConfigIds.responseBufferThreshold, 20 * 1024)
	}
}
