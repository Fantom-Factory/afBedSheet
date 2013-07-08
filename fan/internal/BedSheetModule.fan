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

		binder.bindImpl(ResponseProcessors#)
		binder.bindImpl(ErrProcessors#)

		binder.bindImpl(MoustacheTemplates#)

		binder.bindImpl(BrowserDetection#)
		binder.bindImpl(GzipCompressible#)
		
		binder.bind(HttpRequest#, HttpRequestImpl#).withScope(ServiceScope.perThread)
		binder.bind(HttpResponse#, HttpResponseImpl#).withScope(ServiceScope.perThread)

		binder.bind(Request#, RequestImpl#).withScope(ServiceScope.perThread)
		binder.bind(Response#, ResponseImpl#).withScope(ServiceScope.perThread)

		binder.bindImpl(CrossOriginResourceSharingFilter#)
	}
	
	@Contribute { serviceType=RouteMatchers# }
	static Void contributeRouteMatchers(MappedConfig conf) {
		conf[Route#] 			= conf.autobuild(RouteMatcherImpl#)
	}

	@Contribute { serviceType=ResponseProcessors# }
	static Void contributeResponseProcessors(MappedConfig conf) {
		conf[File#]				= conf.autobuild(FileResponseProcessor#)
		conf[TextResponse#]		= conf.autobuild(TextResponseProcessor#)
	}
	
	@Contribute { serviceType=ErrProcessors# }
	static Void contributeErrProcessors(MappedConfig conf) {
		conf[HttpStatusErr#]	= conf.autobuild(HttpStatusErrProcessor#)
		conf[Err#]				= conf.autobuild(DefaultErrProcessor#)
	}
	
	@Contribute { serviceType=FactoryDefaults# }
	static Void contributeFactoryDefaults(MappedConfig conf) {
		conf[ConfigIds.pingInterval]			= 1sec
		conf[ConfigIds.gzipDisabled]			= false
		conf[ConfigIds.gzipThreshold]			= 376
		conf[ConfigIds.responseBufferThreshold]	= 32 * 1024	// TODO: why not kB?
		
		conf[ConfigIds.corsAllowedOrigins]		= "*"
		conf[ConfigIds.corsExposeHeaders]		= null
		conf[ConfigIds.corsAllowCredentials]	= false
		conf[ConfigIds.corsAllowedMethods]		= "GET, POST"
		conf[ConfigIds.corsAllowedHeaders]		= null
		conf[ConfigIds.corsMaxAge]				= 60min
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
