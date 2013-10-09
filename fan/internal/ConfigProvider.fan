using afIoc::DependencyProvider
using afIoc::Inject
using afIoc::ProviderCtx
using afIocConfig::IocConfigSource

internal const class ConfigProvider : DependencyProvider {

	@Inject
	private const IocConfigSource configSource

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
		value 	:= configSource.getCoerced(id, dependencyType)
		return value
	}
}
