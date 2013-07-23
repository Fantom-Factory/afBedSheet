using afIoc

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