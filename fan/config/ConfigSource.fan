using afIoc::NotFoundErr

const class ConfigSource {
	
	const Str:Obj config
	
	new make(Str:Obj config) {
		this.config = config.toImmutable
	}
	
	Obj get(Str id) {
		config[id] ?: throw NotFoundErr(ConfigMsgs.configNotFound(id), config.keys) 
	}
}
