using afIoc
using afIocConfig::ApplicationDefaults

internal const class T_AppModule {
	
	static Void bind(ServiceBinder binder) {
//		binder.bindImpl(Router#)
	}

	@Contribute { serviceType=Routes# }
	static Void contributeRoutes(OrderedConfig conf, BedSheetPage bedSheetPage) {
		conf.add(Route(`/textResult/plain`,		T_PageHandler#plain))
		conf.add(Route(`/textResult/html`,	 	T_PageHandler#html))
		conf.add(Route(`/textResult/xml`, 		T_PageHandler#xml))

		conf.add(Route(`/jsonResult/list`, 		T_PageHandler#list))

		conf.add(Route(`/route/no-params`, 		T_PageHandler#noParams))
		conf.add(Route(`/route/meth-call-err`, 	T_PageHandler#methodCallErr))
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
		conf.add(Route(`/boom2`,				T_PageHandler#err500))
		conf.add(Route(`/boom3`,				T_PageHandler#iocErr))

		conf.add(Route(`/redirect/movedPerm`,	T_PageHandler#redirectPerm))
		conf.add(Route(`/redirect/movedTemp`,	T_PageHandler#redirectTemp))
		conf.add(Route(`/redirect/afterPost`,	T_PageHandler#afterPost))

		conf.add(Route(`/session`, 				T_PageHandler#countReqs))

		conf.add(Route(`/httpReq1`,				T_PageHandler#httpReq1))
		conf.add(Route(`/httpReq2`,				T_PageHandler#httpReq2))

		conf.add(Route(`/welcome`, 				bedSheetPage.renderWelcome))

		conf.add(Route(`/test-src/***`, 		FileHandler#service))
		conf.add(Route(`/test-src2/***`, 		FileHandler#service))
		
		conf.add(Route(`/res/DeeDee*`, 			T_PageHandler#deeDee))

		conf.add(Route(`/saveAs/*`, 			T_PageHandler#saveAs))

		conf.add(Route(`/saveFlashMsg/*`, 		T_PageHandler#saveFlashMsg))
		conf.add(Route(`/showFlashMsg`, 		T_PageHandler#showFlashMsg))

		conf.add(Route(`/pod/***`, 				PodHandler#service))
		
		// no logging for now!
//		conf.add(Route(`/***`, 					RequestLogFilter#service))
	}

	
	@Contribute { serviceType=ApplicationDefaults# } 
	static Void contributeApplicationDefaults(MappedConfig conf) {
		conf[BedSheetConfigIds.gzipThreshold] 			= 50
//		conf[BedSheetConfigIds.httpRequestLogDir] 		= `./`.toFile
		conf[BedSheetConfigIds.responseBufferThreshold]	= 1 * 1024
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
