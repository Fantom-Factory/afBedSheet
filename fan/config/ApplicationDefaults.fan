using afIoc::NotFoundErr

** Contribute to set application defaults values, overriding any factory defaults. 
**
** @uses a MappedConfig of Str IDs to Objs. Config Obj values must be immutable.
const class ApplicationDefaults {
	const Str:Obj? config
	
	new make(Str:Obj? config) {
		this.config = config.toImmutable
	}
}
