using afIoc

internal const class T_AppModule {
	
	static Void bind(ServiceBinder binder) {
//		binder.bindImpl(Router#)
	}

	@Contribute { serviceType=Routes# }
	static Void contributeRoutes(OrderedConfig conf) {
		conf.add(Route(`/textResult/plain`,		T_PageHandler#plain))
		conf.add(Route(`/textResult/html`,	 	T_PageHandler#html))
		conf.add(Route(`/textResult/xml`, 		T_PageHandler#xml))

		conf.add(Route(`/jsonResult/list`, 		T_PageHandler#list))

		conf.add(Route(`/route/optional/**`, 	T_PageHandler#defaultParams))
		conf.add(Route(`/route/valEnc/*`,		T_PageHandler#valEnc))
		conf.add(Route(`/route/uri/***`, 		T_PageHandler#uri))
		
		conf.add(Route(`/StatusCode/*`, 		T_PageHandler#statusCode))

		conf.add(Route(`/gzip/big`,				T_PageHandler#gzipBig))
		conf.add(Route(`/gzip/small`,			T_PageHandler#gzipSmall))
		conf.add(Route(`/gzip/disable`,			T_PageHandler#gzipDisable))

		conf.add(Route(`/buff/buff`,			T_PageHandler#buff))
		conf.add(Route(`/buff/nobuff`,			T_PageHandler#noBuff))

		conf.add(Route(`/boom`,					T_PageHandler#boom))

		conf.add(Route(`/redirect/movedPerm`,	T_PageHandler#redirectPerm))
		conf.add(Route(`/redirect/movedTemp`,	T_PageHandler#redirectTemp))
		conf.add(Route(`/redirect/afterPost`,	T_PageHandler#afterPost))

		// CORS filters
		conf.add(Route(`/cors/simple`,			CrossOriginResourceSharingFilter#serviceSimple))
		conf.add(Route(`/cors/preflight`,		CrossOriginResourceSharingFilter#servicePrefilght, "OPTIONS"))
		
		// CORS routes
		conf.add(Route(`/cors/simple`,			T_PageHandler#simple))
		conf.add(Route(`/cors/preflight`,		T_PageHandler#preflight, "OPTIONS"))
		
		
		conf.add(Route(`/session`, 				T_PageHandler#countReqs))

		conf.add(Route(`/welcome`, 				WelcomePage#service))

		conf.add(Route(`/test-src/***`, 		FileHandler#service))

		conf.add(Route(`/pod/***`, 				PodHandler#service))
		
		// no logging for now!
//		conf.add(Route(`/***`, 					RequestLogFilter#service))
	}

	
	@Contribute { serviceType=ApplicationDefaults# } 
	static Void contributeApplicationDefaults(MappedConfig conf) {
		conf[ConfigIds.gzipThreshold] = 50
		conf[ConfigIds.requestLogDir] = `./`.toFile
	}
	
	@Contribute { serviceType=ValueEncoders# }
	static Void contributeValueEncoders(MappedConfig conf) {
		conf[Pinky#] = T_PinkyEncoder()
	}

	@Contribute { serviceType=FileHandler# }
	static Void contributeFileMapping(MappedConfig conf) {
		conf[`/test-src/`] = `test/app-web/`.toFile
	}
}