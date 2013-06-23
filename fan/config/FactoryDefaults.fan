using afIoc::NotFoundErr

**
** @uses a MappedConfig of Str IDs to Objs. Config Obj values must be immutable.
const class FactoryDefaults {
	const Str:Obj? config
	
	new make(Str:Obj? config) {
		this.config = config.toImmutable
	}
}
