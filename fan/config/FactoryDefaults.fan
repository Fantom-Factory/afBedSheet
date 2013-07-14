using afIoc::NotFoundErr

** Contribute to set factory default '@Config' values. Only BedSheet and 3rd Party libraries should 
** set / contribute factory defaults. Web applications should override factory defaults by 
** contributing to `ApplicationDefaults`. 
** 
** @uses a MappedConfig of 'Str:Obj' of IDs to Objs. Obj values must be immutable.
const mixin FactoryDefaults {
	@NoDoc
	abstract Str:Obj? config()
}

internal const class FactoryDefaultsImpl : FactoryDefaults {
	override const Str:Obj? config
	
	new make(Str:Obj? config) {
		this.config = config.toImmutable
	}
}
