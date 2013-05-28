using afIoc::DependencyProvider
using afIoc::Inject
using afIoc::ProviderCtx

// TODO: test config service
internal const class ConfigProvider : DependencyProvider {

	@Inject
	private const ConfigSource configSource
	
	new make(|This|in) { in(this) }
	
	override Bool canProvide(ProviderCtx ctx, Type dependencyType) {
		!ctx.facets.findType(Config#).isEmpty
	}

	override Obj provide(ProviderCtx ctx, Type dependencyType) {
		configs	:= ctx.facets.findType(Config#)
		if (configs.size > 1)
			throw Err("WTF")
		
		config := configs[0] as Config
		id := config.id // ?: ctx.paramname
		
		return configSource.get(id)
	}
}
