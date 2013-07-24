using afIoc::Inject
using afIoc::NotFoundErr

** Provides injectable application config values. It lets BedSheet provide default values for you, 
** the user, to override. 
** 
** @see `Config` facet.
**
@NoDoc 
const mixin ConfigSource {	
	abstract Obj? get(Str id)
}

internal const class ConfigSourceImpl : ConfigSource {
	
	private const Str:Obj config

	@Inject  
	private const FactoryDefaults	factoryDefaults
	
	@Inject  
	private const ApplicationDefaults	applicationDefaults
	
	new make(|This|in) {
		in(this)
		config := factoryDefaults.config.rw
		config.setAll(applicationDefaults.config)
		this.config = config.toImmutable
	}
	
	override Obj? get(Str id) {
		if (!config.containsKey(id))
			throw NotFoundErr(ConfigMsgs.configNotFound(id), config.keys)
		return config[id]  
	}
}
