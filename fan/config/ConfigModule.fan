using afIoc

internal class ConfigModule {
	
	static Void bind(ServiceBinder binder) {
		binder.bindImpl(FactoryDefaults#)
		binder.bindImpl(ApplicationDefaults#)
		binder.bindImpl(ConfigSource#)
	}
	
	@Contribute 
	static Void contributeDependencyProviderSource(OrderedConfig conf) {
		configProvider := conf.autobuild(ConfigProvider#)
		conf.add(configProvider)
	}

}
