
internal const class ConfigMsgs {
	
	static Str configNotFound(Str id) {
		"Config id '$id' does not exist"
	}

	static Str configSourceDefaultOverride(Str key) {
		"ApplicationDefaults must override FactoryDefaults : ${key}"
	}
	
}
