using afIoc

internal class TestConfigSource : ConfigTest {
	
	Void testCanOverrideNonExistantConfig() {
		reg := RegistryBuilder().addModule(T_MyModule03#).build.startup
		s04	:= (T_MyService04) reg.serviceById("s04")
		
		// we DO NOT want to throw an err if config is ONLY defined in AppDefaults, 'cos most web 
		// apps (mine included!) will define their OWN config - it's not just about overiding! 
		verifyEq(s04.c01, "Belgium")
	}
	
}

@SubModule { modules=[ConfigModule#] }
internal class T_MyModule03 {
	static Void bind(ServiceBinder binder) {
		binder.bindImpl(T_MyService04#).withId("s04")
	}	

	@Contribute { serviceType=ApplicationDefaults# }
	static Void cuntApp(MappedConfig config) {
		config["c02"] = "Belgium"
	}
}

internal class T_MyService04 {
	@Inject @Config{ id="c02" }	Str? c01
}