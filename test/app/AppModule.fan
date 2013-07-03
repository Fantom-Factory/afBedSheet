using afIoc

internal const class AppModule {
	
	static Void bind(ServiceBinder binder) {
//		binder.bindImpl(Router#)
	}
	
	@Contribute { serviceType=Routes# }
	static Void contributeRoutes(OrderedConfig conf) {
		conf.add(ArgRoute(`/textResult/plain`,	TextPage#plain))
		conf.add(ArgRoute(`/textResult/html`, 	TextPage#html))
		conf.add(ArgRoute(`/textResult/xml`, 	TextPage#xml))

		conf.add(ArgRoute(`/jsonResult/list`, 	JsonPage#list))

		conf.add(ArgRoute(`/route/optional`, 	RoutePage#defaultParams))
		conf.add(ArgRoute(`/route/valEnc`, 		RoutePage#valEnc))
		conf.add(ArgRoute(`/route/uri`, 		RoutePage#uri))
		conf.add(ArgRoute(`/route/list`, 		RoutePage#list))
		
		conf.add(ArgRoute(`/StatusCode`, 		StatusCodePage#statusCode))

		conf.add(ArgRoute(`/gzip/big`,			GzipPage#gzipBig))
		conf.add(ArgRoute(`/gzip/small`,		GzipPage#gzipSmall))
		conf.add(ArgRoute(`/gzip/disable`,		GzipPage#gzipDisable))

		conf.add(ArgRoute(`/boom`,				BoomPage#boom))

		conf.add(ArgRoute(`/cors/simple`,		CrossOriginResourceSharingFilter#serviceSimple))
		conf.add(ArgRoute(`/cors/simple`,		CorsPage#simple))
		conf.add(ArgRoute(`/cors/preflight`,	CrossOriginResourceSharingFilter#servicePrefilght, "OPTIONS"))
		conf.add(ArgRoute(`/cors/preflight`,	CorsPage#preflight, "OPTIONS"))
		
		conf.add(ArgRoute(`/test-src/`, 		FileHandler#service))
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
