using afIoc3
using concurrent::Actor

internal class TestRoutes : BsTest {

	Void handler1(Uri uri) 	{ Actor.locals["handler1"] = true}
	Obj? handler2(Uri uri) 	{ Actor.locals["handler2"] = true; return null }
	Bool handler3(Uri uri) 	{ Actor.locals["handler3"] = true; return false }
	Bool handler4(Uri uri) 	{ Actor.locals["handler4"] = true; return true }
	Bool handler5() 		{ Actor.locals["handler5"] = true; return true }

	Void testFallThrough() {
		reg := RegistryBuilder().addModule(T_MyModule02#).build
		Routes routes := reg.rootScope.serviceByType(Routes#)

		httpReq := T_HttpRequest { it.url = `/1/2/3/4/5`; it.httpMethod = "GET" }
		ret := routes.processRequest(httpReq)

		verify    (ret)
		verify    (Actor.locals["handler1"])
		verify    (Actor.locals["handler2"])
		verify    (Actor.locals["handler3"])
		verify    (Actor.locals["handler4"])
		verifyNull(Actor.locals["handler5"])
	}
}

internal const class T_MyModule02 {
	static Void defineServices(RegistryBuilder defs) {
		defs.addService(Routes#)
		defs.addService(ResponseProcessors#)
		defs.addService(ValueEncoders#)
		defs.addService(ObjCache#)
	}	

	@Contribute { serviceType=Routes# }
	static Void contribute(Configuration conf) {
		conf.add(Route(`/1/***`,		TestRoutes#handler1))
		conf.add(Route(`/1/2/***`,		TestRoutes#handler2))
		conf.add(Route(`/1/2/3/***`,	TestRoutes#handler3))
		conf.add(Route(`/1/2/3/4/***`,	TestRoutes#handler4))
		conf.add(Route(`/1/2/3/4/5`, 	TestRoutes#handler5))
	}
	
	@Contribute { serviceType=ResponseProcessors# }
	static Void contributeResponseProcessors(Configuration conf) {
		conf[MethodCall#]	= conf.build(MethodCallProcessor#)
	}
}
