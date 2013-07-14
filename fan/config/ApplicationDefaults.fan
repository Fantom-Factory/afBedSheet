using afIoc::NotFoundErr

** Contribute to set application default '@Config' values, overriding any factory defaults. 
**
** @uses a MappedConfig of 'Str:Obj' of IDs to Objs. Obj values must be immutable.
const mixin ApplicationDefaults { 
	@NoDoc
	abstract Str:Obj? config()
}

internal const class ApplicationDefaultsImpl : ApplicationDefaults {
	override const Str:Obj? config
	
	new make(Str:Obj? config) {
		this.config = config.toImmutable
	}
}
