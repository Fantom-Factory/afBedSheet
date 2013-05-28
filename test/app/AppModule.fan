using afIoc

internal const class AppModule {
	
	static Void bind(ServiceBinder binder) {
//		binder.bindImpl(Router#)
	}
	
	@Contribute { serviceType=RouteSource# }
	static Void contributeRoutes(OrderedConfig config) {
		config.addUnordered(Route(`/textResult/plain`, 	TextPage#plain))
		config.addUnordered(Route(`/textResult/html`, 	TextPage#html))
		config.addUnordered(Route(`/textResult/xml`, 	TextPage#xml))

		config.addUnordered(Route(`/jsonResult/list`, 	JsonPage#list))

		config.addUnordered(Route(`/route/optional`, 	RoutePage#defaultParams))
		config.addUnordered(Route(`/route/valEnc`, 		RoutePage#valEnc))
		config.addUnordered(Route(`/route/uri`, 		RoutePage#uri))
		config.addUnordered(Route(`/route/list`, 		RoutePage#list))
		
		config.addUnordered(Route(`/StatusCode`, 		StatusCodePage#statusCode))

		config.addUnordered(Route(`/gzip/big`,			GzipPage#gzipBig))
		config.addUnordered(Route(`/gzip/small`,		GzipPage#gzipSmall))

		config.addUnordered(Route(`/boom`,				BoomPage#boom))
		
		config.addUnordered(Route(`/test-src/`, 		FileHandler#service))
	}

	
	@Contribute { serviceType=ConfigSource# } 
	static Void contributeConfig(MappedConfig config) {
		config.addOverride(ConfigIds.gzipThreshold, "my.gzip.threshold", 50)
	}
	
	@Contribute { serviceType=ValueEncoderSource# }
	static Void contributeValueEncoders(MappedConfig config) {
		config.addMapped(Pinky#, 	PinkyEncoder())
	}

	@Contribute { serviceType=FileHandler# }
	static Void contributeFileMapping(MappedConfig config) {
		config.addMapped(`/test-src/`, `test/app-web/`.toFile)
	}

}
