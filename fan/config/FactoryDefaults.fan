using afIoc::NotFoundErr

** Contribute to set factory defaults values. Only BedSheet and 3rd Party libraries should set / 
** contribute factory defaults. Web applications should override factory defaults by contributing
** to `ApplicationDefaults`. 
** 
** @uses a MappedConfig of Str IDs to Objs. Config Obj values must be immutable.
const class FactoryDefaults {
	const Str:Obj? config
	
	new make(Str:Obj? config) {
		this.config = config.toImmutable
	}
}
