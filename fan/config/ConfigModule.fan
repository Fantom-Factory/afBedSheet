using afIoc

internal class ConfigModule {
	
	static Void bind(ServiceBinder binder) {
		// TODO: investiage why proxies cause 'Err: No dependency matches type afIoc::ObjLocator'
		binder.bindImpl(FactoryDefaults#).withoutProxy
		binder.bindImpl(ApplicationDefaults#).withoutProxy
		binder.bindImpl(ConfigSource#)
	}
	
	@Contribute 
	static Void contributeDependencyProviderSource(OrderedConfig conf) {
		configProvider := conf.autobuild(ConfigProvider#)
		conf.add(configProvider)
	}

}
