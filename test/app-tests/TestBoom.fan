using web
using afIoc
using afIocEnv::IocEnv
using afIocConfig::ApplicationDefaults


internal class TestBoom : AppTest {

	override Type[] iocModules	:= [T_AppModule#]
	override Void setup() { }
	
	Void testBoomPage() {
		iocModules	= [T_AppModule#, T_TestBoomMod1#]
		super.setup
		
		client.reqUri = reqUri(`/boom`)
		client.writeReq
		client.readRes
		
		verifyEq(client.resCode, 500)
		verify(client.resStr.contains("Stack Trace"))
		
		// check the handy err headers have been added in dev
		verifyNotNull(client.resHeaders["X-BedSheet-errMsg"])
		verifyNotNull(client.resHeaders["X-BedSheet-errType"])
		verifyNotNull(client.resHeaders["X-BedSheet-errStackTrace"])
	}

	Void testBoomPageInProdModeIsNotScary() {
		iocModules	= [T_AppModule#, T_TestBoomMod2#]
		super.setup

		client.reqUri = reqUri(`/boom`)
		client.writeReq
		client.readRes

		verifyEq(client.resCode, 500)
		verifyFalse(client.resStr.contains("Stack Trace"))
		
		// check the handy err headers are dev only
		verifyNull(client.resHeaders["X-BedSheet-errMsg"])
		verifyNull(client.resHeaders["X-BedSheet-errType"])
		verifyNull(client.resHeaders["X-BedSheet-errStackTrace"])
	}

	Void testErr500WithNoErr() {
		super.setup
		
		client.reqUri = reqUri(`/boom2`)
		client.writeReq
		client.readRes
		
		verifyEq(client.resCode, 500)
		verify(client.resStr.contains("Alien-Factory"))
	}

	Void testErrPagesWillNeverDie() {
		iocModules	= [T_AppModule#, T_TestBoomMod3#]
		super.setup
		
		client.reqUri = reqUri(`/boom`)
		client.writeReq
		client.readRes

		verifyEq(client.resCode, 500)
		verify(client.resStr.contains("Fantom Diagnostics"))
	}
}

internal class T_TestBoomMod1 {
    @Contribute { serviceType=ServiceOverrides# }
    static Void contributeServiceOverride(MappedConfig config) {
        config["IocEnv"] = IocEnv.fromStr("dev")
    }
}

internal class T_TestBoomMod2 {
    @Contribute { serviceType=ServiceOverrides# }
    static Void contributeServiceOverride(MappedConfig config) {
        config["IocEnv"] = IocEnv.fromStr("prod")
    }
}

internal class T_TestBoomMod3 {
	@Contribute { serviceType=ErrPrinterHtml# } 
	static Void contributeErrPrinterHtml(OrderedConfig config) {
		config.addOrdered("Die", |WebOutStream out, Err? err| { throw Err("Ouch!") }, ["before: RequestDetails"])
	}

	@Contribute { serviceType=ErrPrinterStr# } 
	static Void contributeErrPrinterStr(OrderedConfig config) {
		config.addOrdered("Die", |StrBuf out, Err? err| { throw Err("Ouch!") }, ["before: RequestDetails"])
	}
}