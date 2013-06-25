using afIoc

internal class TestCoors : AppTest {

	override Type[] iocModules	:= [,]
	override Void setup() { }
	
//	Void testOriginNotMatch() {
//		
//	}
	
	Void testSimpleReqWorks() {
		iocModules = [T_CorsMod1#]
		super.setup

		client.reqHeaders["origin"] = "http://api.bob.com"
		client.reqUri = reqUri(`/cors/simple`)
		client.writeReq
		client.readRes
		
		verifyEq(client.resHeader("Access-Control-Allow-Origin"), "http://api.bob.com")
	}
}

internal class T_CorsMod1 {
	static Void contributeApplicationDefaults(MappedConfig config) {
		config.addMapped(ConfigIds.corsAllowedOrigins, "http://api.bob.com, bobby.com")
	}
}