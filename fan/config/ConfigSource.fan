
const class ConfigSource {
	
	const Str:Obj config
	
	new make(Str:Obj config) {
		this.config = config.toImmutable
	}
	
	Obj get(Str id) {
		// TODO: throw nice Err msg when not found
		config[id]
	}
}
