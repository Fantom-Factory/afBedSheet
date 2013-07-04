using afIoc

internal const class AppModule {
	
	static Void bind(ServiceBinder binder) {
//		binder.bindImpl(Router#)
	}
	
	@Contribute { serviceType=Routes# }
	static Void contributeRoutes(OrderedConfig conf) {
		conf.add(Route(`/textResult/plain`,	TextPage#plain))
		conf.add(Route(`/textResult/html`, 	TextPage#html))
		conf.add(Route(`/textResult/xml`, 	TextPage#xml))

		conf.add(Route(`/jsonResult/list`, 	JsonPage#list))

		conf.add(Route(`/route/optional`, 	RoutePage#defaultParams))
		conf.add(Route(`/route/valEnc`, 	RoutePage#valEnc))
		conf.add(Route(`/route/uri`, 		RoutePage#uri))
		conf.add(Route(`/route/list`, 		RoutePage#list))
		
		conf.add(Route(`/StatusCode`, 		StatusCodePage#statusCode))

		conf.add(Route(`/gzip/big`,			GzipPage#gzipBig))
		conf.add(Route(`/gzip/small`,		GzipPage#gzipSmall))
		conf.add(Route(`/gzip/disable`,		GzipPage#gzipDisable))

		conf.add(Route(`/boom`,				BoomPage#boom))

		conf.add(Route(`/cors/simple`,		CrossOriginResourceSharingFilter#serviceSimple))
		conf.add(Route(`/cors/simple`,		CorsPage#simple))
		conf.add(Route(`/cors/preflight`,	CrossOriginResourceSharingFilter#servicePrefilght, "OPTIONS"))
		conf.add(Route(`/cors/preflight`,	CorsPage#preflight, "OPTIONS"))
		
		conf.add(Route(`/test-src/`, 		FileHandler#service))
	}

	
	@Contribute { serviceType=ApplicationDefaults# } 
	static Void contributeApplicationDefaults(MappedConfig conf) {
		conf[ConfigIds.gzipThreshold] = 50
	}
	
	@Contribute { serviceType=ValueEncoderSource# }
	static Void contributeValueEncoders(MappedConfig conf) {
		conf[Pinky#] = PinkyEncoder()
	}

	@Contribute { serviceType=FileHandler# }
	static Void contributeFileMapping(MappedConfig conf) {
		conf[`/test-src/`] = `test/app-web/`.toFile
	}
}
