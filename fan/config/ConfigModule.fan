using afIoc

class ConfigModule {
	
	static Void bind(ServiceBinder binder) {
		binder.bindImpl(ConfigSource#)
	}
	
	@Contribute 
	static Void contributeDependencyProviderSource(OrderedConfig config) {
		configProvider := config.autobuild(ConfigProvider#)
		config.addUnordered(configProvider)
	}

}
