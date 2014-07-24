using afIoc
using concurrent::Actor

internal class TestRoutes : BsTest {

	Void handler1(Uri uri) 	{ Actor.locals["handler1"] = true}
	Obj? handler2(Uri uri) 	{ Actor.locals["handler2"] = true; return null }
	Bool handler3(Uri uri) 	{ Actor.locals["handler3"] = true; return false }
	Bool handler4(Uri uri) 	{ Actor.locals["handler4"] = true; return true }
	Bool handler5() 		{ Actor.locals["handler5"] = true; return true }

	Void testFallThrough() {
		reg := RegistryBuilder().addModule(T_MyModule02#).build.startup
		Routes routes := reg.serviceById("routes")

		ret := routes.processRequest(`/1/2/3/4/5`, "GET")

		verify    (ret)
		verify    (Actor.locals["handler1"])
		verify    (Actor.locals["handler2"])
		verify    (Actor.locals["handler3"])
		verify    (Actor.locals["handler4"])
		verifyNull(Actor.locals["handler5"])
	}
}

internal class T_MyModule02 {
	static Void bind(ServiceBinder binder) {
		binder.bind(Routes#)
		binder.bind(ResponseProcessors#)
		binder.bind(MethodCallResponseProcessor#)
		binder.bind(ValueEncoders#)
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
		conf[MethodCall#]	= conf.autobuild(MethodCallResponseProcessor#)
	}
}
