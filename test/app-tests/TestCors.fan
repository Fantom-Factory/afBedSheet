using afIoc

internal class TestCoors : AppTest {

	override Type[] iocModules	:= [,]
	override Void setup() { }

	Void testSimpleReqWorks() {
		iocModules = [T_AppModule#, T_CorsMod1#]
		super.setup

		client.reqHeaders["origin"] = "http://api.bob.com"
		client.reqUri = reqUri(`/cors/simple`)
		client.writeReq
		client.readRes
		
		verifyEq(client.resHeader("Access-Control-Allow-Origin"), "http://api.bob.com")
		verifyNull(client.resHeaders.get("Access-Control-Allow-Credentials", null))
		verifyNull(client.resHeaders.get("Access-Control-Expose-Headers", null))
		verifyEq(client.resCode, 200)
	}
	
	Void testOriginMisMatch() {
		iocModules = [T_AppModule#, T_CorsMod2#]
		super.setup
		
		client.reqHeaders["origin"] = "http://api.bob.com"
		client.reqUri = reqUri(`/cors/simple`)
		client.writeReq
		client.readRes
		
		verifyNull(client.resHeaders.get("Access-Control-Allow-Origin", null))
		verifyEq(client.resCode, 200)
	}

	Void testAllowedCredentials() {
		iocModules = [T_AppModule#, T_CorsMod3#]
		super.setup
		
		client.reqHeaders["origin"] = "http://api.bob.com"
		client.reqUri = reqUri(`/cors/simple`)
		client.writeReq
		client.readRes
		
		verifyEq(client.resHeaders["Access-Control-Allow-Credentials"], "true")
		verifyEq(client.resCode, 200)
	}

	Void testExposeHeaders() {
		iocModules = [T_AppModule#, T_CorsMod4#]
		super.setup
		
		client.reqHeaders["origin"] = "http://api.bob.com"
		client.reqUri = reqUri(`/cors/simple`)
		client.writeReq
		client.readRes
		
		verifyEq(client.resHeaders["Access-Control-Expose-Headers"], "Max-Headroom")
		verifyEq(client.resCode, 200)
	}

	Void testPreflight() {
		iocModules = [T_AppModule#, T_CorsMod5#]
		super.setup
		
		client.reqHeaders["origin"] = "http://api.bob.com"
		client.reqHeaders["Access-Control-Request-Method"] = "POST"
		client.reqMethod = "OPTIONS"
		client.reqUri = reqUri(`/cors/preflight`)
		client.writeReq
		client.readRes
		
		verifyEq(client.resHeaders["Access-Control-Allow-Origin"], "http://api.bob.com")
		verifyEq(client.resHeaders["Access-Control-Allow-Methods"], "GET, POST")
		verifyEq(client.resCode, 200)
	}
}

internal class T_CorsMod1 {
	@Contribute
	static Void contributeApplicationDefaults(MappedConfig config) {
		config.set(ConfigIds.corsAllowedOrigins, "http://api.bob.com, bobby.com")
	}
}

internal class T_CorsMod2 {
	@Contribute
	static Void contributeApplicationDefaults(MappedConfig config) {
		config.set(ConfigIds.corsAllowedOrigins, null)
	}
}

internal class T_CorsMod3 {
	@Contribute
	static Void contributeApplicationDefaults(MappedConfig config) {
		config.set(ConfigIds.corsAllowCredentials, true)
	}
}

internal class T_CorsMod4 {
	@Contribute
	static Void contributeApplicationDefaults(MappedConfig config) {
		config.set(ConfigIds.corsExposeHeaders, "Max-Headroom")
	}
}

internal class T_CorsMod5 {
	@Contribute
	static Void contributeApplicationDefaults(MappedConfig config) {
//		config.set(ConfigIds.corsExposeHeaders, "Max-Headroom")
	}
}
