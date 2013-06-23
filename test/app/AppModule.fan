using afIoc

internal const class AppModule {
	
	static Void bind(ServiceBinder binder) {
//		binder.bindImpl(Router#)
	}
	
	@Contribute { serviceType=Routes# }
	static Void contributeRoutes(OrderedConfig config) {
		config.addUnordered(ArgRoute(`/textResult/plain`, 	TextPage#plain))
		config.addUnordered(ArgRoute(`/textResult/html`, 	TextPage#html))
		config.addUnordered(ArgRoute(`/textResult/xml`, 	TextPage#xml))

		config.addUnordered(ArgRoute(`/jsonResult/list`, 	JsonPage#list))

		config.addUnordered(ArgRoute(`/route/optional`, 	RoutePage#defaultParams))
		config.addUnordered(ArgRoute(`/route/valEnc`, 		RoutePage#valEnc))
		config.addUnordered(ArgRoute(`/route/uri`, 			RoutePage#uri))
		config.addUnordered(ArgRoute(`/route/list`, 		RoutePage#list))
		
		config.addUnordered(ArgRoute(`/StatusCode`, 		StatusCodePage#statusCode))

		config.addUnordered(ArgRoute(`/gzip/big`,			GzipPage#gzipBig))
		config.addUnordered(ArgRoute(`/gzip/small`,			GzipPage#gzipSmall))
		config.addUnordered(ArgRoute(`/gzip/disable`,		GzipPage#gzipDisable))

		config.addUnordered(ArgRoute(`/boom`,				BoomPage#boom))
		
		config.addUnordered(ArgRoute(`/test-src/`, 			FileHandler#service))
	}

	
	@Contribute { serviceType=ApplicationDefaults# } 
	static Void contributeConfig(MappedConfig config) {
		config.addMapped(ConfigIds.gzipThreshold, 50)
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
