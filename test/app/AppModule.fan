using afIoc

internal const class AppModule {
	
	static Void bind(ServiceBinder binder) {
//		binder.bindImpl(Router#)
	}
	
	@Contribute { serviceType=Router# }
	static Void configureRouter(OrderedConfig config) {
		config.addUnordered(Route(`/textResult/plain`, 	TextPage#plain))
		config.addUnordered(Route(`/textResult/html`, 	TextPage#html))
		config.addUnordered(Route(`/textResult/xml`, 	TextPage#xml))

		config.addUnordered(Route(`/jsonResult/list`, 	JsonPage#list))

		config.addUnordered(Route(`/route/optional`, 	RoutePage#defaultParams))
		config.addUnordered(Route(`/route/valEnc`, 		RoutePage#valEnc))
		
		config.addUnordered(Route(`/StatusCode`, 		StatusCodePage#statusCode))

		config.addUnordered(Route(`/gzip/big`,			GzipPage#gzipBig))
		config.addUnordered(Route(`/gzip/small`,		GzipPage#gzipSmall))
		
//		config.addUnordered(Route(`/pub/`, 	FileHandler#service))
	}

	
	@Contribute { serviceType=ConfigSource# } 
	static Void configureConfigSource(MappedConfig config) {
//		config.addOverride(ConfigIds.gzipThreshold, "app.gzip.threshold", 50)
//		config.addMapped(ConfigIds.gzipThreshold, 50)
		config.addOverride(ConfigIds.gzipThreshold, "wowt", 50)
	}
	
	@Contribute { serviceType=ValueEncoderSource# }
	static Void configureValueEncoderSource(MappedConfig config) {
		config.addMapped(Pinky#, 	PinkyEncoder())
	}

	@Contribute { serviceType=FileHandler# }
	static Void configureFileServer(MappedConfig config) {
//		config.addMapped(`/pub/`, `etc/web/`.toFile)
	}
	
}
