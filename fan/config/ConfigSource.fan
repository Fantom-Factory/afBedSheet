using afIoc::ConcurrentState
using afIoc::Inject
using afIoc::NotFoundErr
using afIoc::TypeCoercer

** Provides injectable application config values. It lets BedSheet provide default values for you, 
** the user, to override. 
** 
** @see `Config` facet.
**
@NoDoc 
const mixin ConfigSource {	
	@Operator
	abstract Obj? get(Str id)

	abstract Obj? getCoerced(Str id, Type coerceTo)
}

internal const class ConfigSourceImpl : ConfigSource {
	private const ConcurrentState 	conState	:= ConcurrentState(ConfigSourceState#)

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
	
	override Obj? getCoerced(Str id, Type coerceTo) {
		value 	:= get(id)
		coerced	:= (value == null) ? null : getState() { it.typeCoercer.coerce(value, coerceTo) }
		return coerced
	}
	
	private Obj? getState(|ConfigSourceState -> Obj| state) {
		conState.getState(state)
	}
}

internal class ConfigSourceState {
	TypeCoercer	typeCoercer	:= TypeCoercer()
}