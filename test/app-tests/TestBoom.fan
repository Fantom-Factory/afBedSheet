using afIoc
using web

internal class TestBoom : AppTest {

	override Type[] iocModules	:= [T_AppModule#]
	override Void setup() { }
	
	Void testBoomPage() {
		super.setup
		
		client.reqUri = reqUri(`/boom`)
		client.writeReq
		client.readRes
		
		verifyEq(client.resCode, 500)
		verify(client.resStr.contains("Stack Trace"))
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
		iocModules	= [T_AppModule#, T_TestBoomMod2#]
		super.setup
		
		client.reqUri = reqUri(`/boom`)
		client.writeReq
		client.readRes
		
		verifyEq(client.resCode, 500)
		verify(client.resStr.contains("Fantom Diagnostics"))
	}

	Void testBoomPageInProdModeIsNotScary() {
		iocModules	= [T_AppModule#, T_TestBoomMod#]
		super.setup
		
		client.reqUri = reqUri(`/boom`)
		client.writeReq
		client.readRes
		
		verifyEq(client.resCode, 500)
		verifyFalse(client.resStr.contains("Stack Trace"))
	}
}

internal class T_TestBoomMod {
	@Contribute { serviceType=ApplicationDefaults# } 
	static Void contributeApplicationDefaults(MappedConfig conf) {
		conf[ConfigIds.errPageDisabled] = true
	}
}

internal class T_TestBoomMod2 {
	@Contribute { serviceType=ErrPrinterHtml# } 
	static Void contributeErrPrinterHtml(OrderedConfig config) {
		config.addOrdered("Die", |WebOutStream out, Err? err| { throw Err("Ouch!") }, ["before: Request"])
	}

	@Contribute { serviceType=ErrPrinterStr# } 
	static Void contributeErrPrinterStr(OrderedConfig config) {
		config.addOrdered("Die", |StrBuf out, Err? err| { throw Err("Ouch!") }, ["before: Request"])
	}
}