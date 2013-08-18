using afIoc::Contribute
using afIoc::MappedConfig
using afIoc::ServiceBinder

internal class MoustacheModule {
	
	static Void bind(ServiceBinder binder) {
		binder.bindImpl(MoustacheTemplates#).withoutProxy		// has default method args		
	}
	
	@Contribute { serviceType=FactoryDefaults# }
	static Void contributeFactoryDefaults(MappedConfig config, HttpStatusPageDefault defaultStatusPage) {
		config[MoustacheConfigIds.moustacheTemplateTimeout]		= 10sec
	}
}
