using afIoc

class TestConfig : Test {
	
	Void testFactoryDef() {
		reg := RegistryBuilder().addModule(T_MyModule01#).build.startup
		s01	:= (T_MyService01) reg.serviceById("s01")
		verifyEq(s01.c01, "Belgium")
	}

	Void testAppDef() {
		reg := RegistryBuilder().addModule(T_MyModule01#).build.startup
		s01	:= (T_MyService01) reg.serviceById("s01")
		verifyEq(s01.c02, "Belgium")
	}

	Void testAppOverridesFactory() {
		reg := RegistryBuilder().addModule(T_MyModule01#).build.startup
		s01	:= (T_MyService01) reg.serviceById("s01")
		verifyEq(s01.c03, "Belgium")
	}

	Void testNullFactoryFactory() {
		reg := RegistryBuilder().addModule(T_MyModule01#).build.startup
		s01	:= (T_MyService01) reg.serviceById("s01")
		verifyEq(s01.c05, null)
	}

	Void testNullAppFactory() {
		reg := RegistryBuilder().addModule(T_MyModule01#).build.startup
		s01	:= (T_MyService01) reg.serviceById("s01")
		verifyEq(s01.c06, null)
	}

	Void testNullAppOverrideFactory() {
		reg := RegistryBuilder().addModule(T_MyModule01#).build.startup
		s01	:= (T_MyService01) reg.serviceById("s01")
		verifyEq(s01.c07, null)
	}

	Void testConfigNotExist() {
		reg := RegistryBuilder().addModule(T_MyModule01#).build.startup
		try {
			s02	:= (T_MyService02) reg.serviceById("s02")
			fail
		} catch (IocErr e) { }
	}
	
}

@SubModule { modules=[ConfigModule#] }
internal class T_MyModule01 {
	static Void bind(ServiceBinder binder) {
		binder.bindImpl(T_MyService01#).withId("s01")
		binder.bindImpl(T_MyService02#).withId("s02")
	}	

	@Contribute { serviceType=FactoryDefaults# }
	static Void cuntFuct(MappedConfig config) {
		config.addMapped("c01", "Belgium")	// factory value
		config.addMapped("c03", "UK")		// app override
		
		config.addMapped("c05", null)		// null factory value
		config.addMapped("c07", "belgium")	// null factory value
	}

	@Contribute { serviceType=ApplicationDefaults# }
	static Void cuntApp(MappedConfig config) {
		config.addMapped("c02", "Belgium")	// app value
		config.addMapped("c03", "Belgium")	// app override
		
		config.addMapped("c06", null)		// null app value
		config.addMapped("c07", null)		// null app override
	}
}

internal class T_MyService01 {
	@Inject @Config{ id="c01" }	Str? c01
	@Inject @Config{ id="c02" }	Str? c02
	@Inject @Config{ id="c03" }	Str? c03
	
	@Inject @Config{ id="c05" }	Str? c05
	@Inject @Config{ id="c06" }	Str? c06
	@Inject @Config{ id="c07" }	Str? c07
}

internal class T_MyService02 {
	// c04 doesn't exist
	@Inject @Config{ id="c04" }	Str? c04
	
}
