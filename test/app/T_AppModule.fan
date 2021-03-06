using afIoc
using afIocConfig::ApplicationDefaults

internal const class T_AppModule {
	
	static Void defineServices(RegistryBuilder defs) {
//		defs.adderviceType(...)
	}

	@Contribute { serviceType=Routes# }
	static Void contributeRoutes(Configuration conf, BedSheetPages bedSheetPages) {
		conf.add(Route(`/textResult/plain`,		T_PageHandler#plain, "GET HEAD"))
		conf.add(Route(`/textResult/html`,	 	T_PageHandler#html))
		conf.add(Route(`/textResult/xml`, 		T_PageHandler#xml))

		conf.add(Route(`/jsonResult/list`, 		T_PageHandler#list))

		conf.add(Route(`/route/no-params`, 		T_PageHandler#noParams))
		conf.add(Route(`/route/meth-call-err`, 	T_PageHandler#methodCallErr))
		conf.add(Route(`/route/optional/*/*/*`,	T_PageHandler#defaultParams))
		conf.add(Route(`/route/valEnc/*`,		T_PageHandler#valEnc))
		conf.add(Route(`/route/uri/**`, 		T_PageHandler#uri))
		
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
		conf.add(Route(`/sessionImmutable1`,	T_PageHandler#sessionImmutable1))
		conf.add(Route(`/sessionImmutable2`,	T_PageHandler#sessionImmutable2))
		conf.add(Route(`/sessionSerialisable1`,	T_PageHandler#sessionSerialisable1))
		conf.add(Route(`/sessionSerialisable2`,	T_PageHandler#sessionSerialisable2))
		conf.add(Route(`/sessionMutable1`,		T_PageHandler#sessionMutable1))
		conf.add(Route(`/sessionMutable2`,		T_PageHandler#sessionMutable2))
		conf.add(Route(`/sessionMutable3`,		T_PageHandler#sessionMutable3))
		conf.add(Route(`/sessionBad`,			T_PageHandler#sessionBad))
		conf.add(Route(`/sessionDelete`,		T_PageHandler#sessionDelete))

		conf.add(Route(`/httpReq1`,				T_PageHandler#httpReq1))
		conf.add(Route(`/httpReq2`,				T_PageHandler#httpReq2))

		conf.add(Route(`/welcome`, 				T_PageHandler#renderWelcome))

		conf.add(Route(`/fh/test-src/**`, 		T_PageHandler#altFileHandler))
		
		conf.add(Route(`/res/DeeDee/*`, 		T_PageHandler#deeDee))

		conf.add(Route(`/saveAs/*`, 			T_PageHandler#saveAs))

		conf.add(Route(`/saveFlashMsg/*`, 		T_PageHandler#saveFlashMsg))
		conf.add(Route(`/showFlashMsg`, 		T_PageHandler#showFlashMsg))

		conf.add(Route(`/slow`, 				T_PageHandler#slow))

		conf.add(Route(`/postForm`, 			T_PageHandler#postForm, "POST"))
		conf.add(Route(`/postMultipartForm`, 	T_PageHandler#postMultipartForm, "POST"))

		conf.add(Route(`/fieldResponse`,		T_PageHandler#fieldResponse))

		conf.add(Route(`/onCommit`,				T_PageHandler#onCommit))
		
		// no logging for now!
//		conf.add(Route(`/***`, 					RequestLogFilter#service))
	}

	
	@Contribute { serviceType=ApplicationDefaults# } 
	static Void contributeApplicationDefaults(Configuration conf) {
		conf[BedSheetConfigIds.gzipThreshold] 			= 50
//		conf[BedSheetConfigIds.requestLogDir] 			= `./`.toFile
		conf[BedSheetConfigIds.responseBufferThreshold]	= 1 * 1024
	}
	
	@Contribute { serviceType=ValueEncoders# }
	static Void contributeValueEncoders(Configuration conf) {
		conf[Pinky#] = T_PinkyEncoder()
	}

	@Contribute { serviceType=FileHandler# }
	static Void contributeFileMapping(Configuration conf) {
		conf[`/test-src/`] = `test/app-web/`.toFile
	}

//	@Contribute { serviceType=RegistryStartup# }
//	static Void contributeRegStartup(Configuration conf) {
//		conf.remove("afIoc.logBanner")
//	}
}
