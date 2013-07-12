using afIoc::ConcurrentState
using afIoc::DependencyProvider
using afIoc::Inject
using afIoc::ProviderCtx
using afIoc::TypeCoercer

internal const class ConfigProvider : DependencyProvider {
	private const ConcurrentState 	conState	:= ConcurrentState(ConfigProviderState#)
	
	@Inject
	private const ConfigSource configSource
	
	new make(|This|in) { in(this) }
	
	override Bool canProvide(ProviderCtx ctx, Type dependencyType) {
		!ctx.facets.findType(Config#).isEmpty
	}

	override Obj? provide(ProviderCtx ctx, Type dependencyType) {
		configs	:= ctx.facets.findType(Config#)
		if (configs.size > 1)
			throw Err("WTF")
		
		config 	:= (Config) configs[0]
		id 		:= config.id // ?: ctx.paramname
		val 	:= configSource.get(id)
		coerced	:= (val == null) ? null : getState() { it.typeCoercer.coerce(val, dependencyType) }
		
		return coerced
	}
	
	private Obj? getState(|ConfigProviderState -> Obj| state) {
		conState.getState(state)
	}
}

internal class ConfigProviderState {
	TypeCoercer	typeCoercer	:= TypeCoercer()
}