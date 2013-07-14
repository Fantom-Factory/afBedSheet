using afIoc

internal class TestConfigSource : ConfigTest {
	
	Void testCannotOverrideNonExistantConfig() {
		verifyConfigErrMsg(ConfigMsgs.configSourceDefaultOverride("c02")) {
			reg := RegistryBuilder().addModule(T_MyModule03#).build.startup
			s04	:= (T_MyService04) reg.serviceById("s04")
		}
	}
	
}

@SubModule { modules=[ConfigModule#] }
internal class T_MyModule03 {
	static Void bind(ServiceBinder binder) {
		binder.bindImpl(T_MyService04#).withId("s04")
	}	

	@Contribute { serviceType=FactoryDefaults# }
	static Void cuntFuct(MappedConfig config) {
		config["c01"] = "Belgium"
	}

	@Contribute { serviceType=ApplicationDefaults# }
	static Void cuntApp(MappedConfig config) {
		config["c02"] = "Belgium"
	}
}

internal class T_MyService04 {
	@Inject @Config{ id="c01" }	Str? c01
}