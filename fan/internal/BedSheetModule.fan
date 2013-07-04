using afIoc
using web
using concurrent

@SubModule { modules=[ConfigModule#] }
internal class BedSheetModule {
	
	static Void bind(ServiceBinder binder) {
		binder.bindImpl(BedSheetService#)
		
		binder.bindImpl(Routes#)
		binder.bindImpl(RouteMatcherSource#)
		binder.bindImpl(ReqestHandlerInvoker#)

		binder.bindImpl(ValueEncoderSource#)
		binder.bindImpl(FileHandler#)

		binder.bindImpl(ResultProcessorSource#)
		binder.bindImpl(ErrProcessorSource#)

		binder.bindImpl(MoustacheSource#)

		binder.bindImpl(BrowserDetection#)
		binder.bindImpl(GzipCompressible#)
		
		binder.bindImpl(Request#).withScope(ServiceScope.perThread)
		binder.bindImpl(Response#).withScope(ServiceScope.perThread)

		binder.bindImpl(CrossOriginResourceSharingFilter#)
	}

	@Contribute { serviceType=RouteMatcherSource# }
	static Void contributeRouteMatcherSource(MappedConfig config) {
		config[ArgRoute#] = config.autobuild(RouteMatcherArgImpl#)
//		config[PathMapRoute#]	= config.autobuild(RouteMatcherPathMapImpl#)
//		config[ExactRoute#]		= config.autobuild(RouteMatcherExactImpl#)
	}

	@Contribute { serviceType=ResultProcessorSource# }
	static Void contributeResultProcessorSource(MappedConfig conf) {
		conf[File#]			= conf.autobuild(FileResultProcessor#)
		conf[TextResult#]	= conf.autobuild(TextResultProcessor#)
	}
	
	@Contribute { serviceType=ErrProcessorSource# }
	static Void contributeErrProcessorSource(MappedConfig conf) {
		conf[HttpStatusErr#]	= conf.autobuild(HttpStatusErrProcessor#)
		conf[Err#]				= conf.autobuild(DefaultErrProcessor#)
	}
	
	@Contribute { serviceType=FactoryDefaults# }
	static Void contributeFactoryDefaults(MappedConfig conf) {
		conf[ConfigIds.pingInterval]			= 1sec
		conf[ConfigIds.gzipDisabled]			= false
		conf[ConfigIds.gzipThreshold]			= 376
		conf[ConfigIds.responseBufferThreshold]	= 8 * 1024	// TODO: why not kB?
		
		conf[ConfigIds.corsAllowedOrigins]		= "*"
		conf[ConfigIds.corsExposeHeaders]		= null
		conf[ConfigIds.corsAllowCredentials]	= false
		conf[ConfigIds.corsAllowedMethods]		= "GET, POST"
		conf[ConfigIds.corsAllowedHeaders]		= null
		conf[ConfigIds.corsMaxAge]				= 60min
	}

	@Contribute { serviceType=ValueEncoderSource# }
	static Void contributeValueEncoderSource(MappedConfig config) {
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
