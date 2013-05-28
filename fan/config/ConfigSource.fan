using afIoc::NotFoundErr

** Provides injectable application config values. It lets BedSheet provide default values for you, 
** the user, to override. 
** 
** @see `Config` facet.
** 
** @uses a MappedConfig of Str IDs to Objs. Config Obj values must be immutable.
const class ConfigSource {
	
	const Str:Obj config
	
	new make(Str:Obj config) {
		this.config = config.toImmutable
	}
	
	Obj get(Str id) {
		config[id] ?: throw NotFoundErr(ConfigMsgs.configNotFound(id), config.keys) 
	}
}
