using afIoc
using web
using concurrent

@SubModule { modules=[ConfigModule#] }
internal class BedSheetModule {
	
	static Void bind(ServiceBinder binder) {
		binder.bindImpl(BedSheetService#)
		
		binder.bindImpl(Routes#)
		binder.bindImpl(RouteMatchers#)
		binder.bindImpl(ReqestHandlerInvoker#)

		binder.bindImpl(ValueEncoders#)
		binder.bindImpl(FileHandler#)

		binder.bindImpl(HttpStatusProcessors#)
		binder.bindImpl(ResponseProcessors#)
		binder.bindImpl(ErrProcessors#)

		binder.bindImpl(MoustacheTemplates#)

		binder.bindImpl(BrowserDetection#)
		binder.bindImpl(GzipCompressible#)
		
		binder.bindImpl(HttpRequest#)
		binder.bindImpl(HttpResponse#)
		binder.bindImpl(HttpSession#)

		binder.bind(Request#, RequestImpl#)
		binder.bind(Response#, ResponseImpl#)

		binder.bindImpl(CrossOriginResourceSharingFilter#)
		binder.bindImpl(IeAjaxCacheBustingFilter#)
		binder.bindImpl(RequestLogFilter#)
	}

	@Contribute { serviceType=RouteMatchers# }
	static Void contributeRouteMatchers(MappedConfig conf) {
		conf[Route#] 			= conf.autobuild(RouteMatcherImpl#)
	}

	@Contribute { serviceType=ResponseProcessors# }
	static Void contributeResponseProcessors(MappedConfig conf, HttpStatusProcessors httpStatusProcessor) {
		conf[File#]				= conf.autobuild(FileResponseProcessor#)
		conf[TextResponse#]		= conf.autobuild(TextResponseProcessor#)
		conf[HttpStatus#]		= httpStatusProcessor
	}

	@Contribute { serviceType=HttpStatusProcessors# }
	static Void contributeHttpStatusProcessor(MappedConfig conf) {
		conf[500]				= conf.autobuild(HttpStatusPage500#)
	}

	@Contribute { serviceType=ErrProcessors# }
	static Void contributeErrProcessors(MappedConfig conf) {
		conf[HttpStatusErr#]	= conf.autobuild(HttpStatusErrProcessor#)
		conf[Err#]				= conf.autobuild(DefaultErrProcessor#)
	}

	@Contribute { serviceType=FactoryDefaults# }
	static Void contributeFactoryDefaults(MappedConfig conf) {
		conf[ConfigIds.proxyPingInterval]			= 1sec
		conf[ConfigIds.gzipDisabled]				= false
		conf[ConfigIds.gzipThreshold]				= 376
		conf[ConfigIds.responseBufferThreshold]		= 32 * 1024	// TODO: why not kB?
		conf[ConfigIds.httpStatusDefaultPage]		= conf.autobuild(HttpStatusPageDefault#)
				
		conf[ConfigIds.requestLogDir]				= null
		conf[ConfigIds.requestLogFilenamePattern]	= "afBedSheet-{YYYY-MM}.log"
		conf[ConfigIds.requestLogFields]			= "date time c-ip cs(X-Real-IP) cs-method cs-uri-stem cs-uri-query sc-status time-taken cs(User-Agent) cs(Referer) cs(Cookie)"
		
		conf[ConfigIds.corsAllowedOrigins]			= "*"
		conf[ConfigIds.corsExposeHeaders]			= null
		conf[ConfigIds.corsAllowCredentials]		= false
		conf[ConfigIds.corsAllowedMethods]			= "GET, POST"
		conf[ConfigIds.corsAllowedHeaders]			= null
		conf[ConfigIds.corsMaxAge]					= 60min
	}

	@Contribute { serviceType=ValueEncoders# }
	static Void contributeValueEncoders(MappedConfig config) {
		// wot no value encoders!? Aha! I see you're using fromStr() instead!
	}

	@Contribute { serviceType=GzipCompressible# }
	static Void contributeGzipCompressible(MappedConfig conf) {
		// add some standard compressible mime types
		conf["text/plain"]					= true
		conf["text/css"]					= true
		conf["text/tab-separated-values"]	= true
		conf["text/html"]					= true
		conf["text/javascript"]				= true
		conf["text/xml"]					= true
		conf["application/rss+xml"]			= true
		conf["application/json"]			= true
	}
	
	@Build { serviceId="WebReq"; scope=ServiceScope.perThread }	
	private static WebReq buildWebReq() {
		try return Actor.locals["web.req"]
		catch (NullErr e) 
			throw Err("No web request active in thread")
	}

	@Build { serviceId="WebRes"; scope=ServiceScope.perThread } 
	private static WebRes buildWebRes() {
		try return Actor.locals["web.res"]
		catch (NullErr e)
			throw Err("No web request active in thread")
	}
}
