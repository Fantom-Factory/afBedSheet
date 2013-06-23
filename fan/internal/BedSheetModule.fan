using afIoc
using web
using concurrent

@SubModule { modules=[ConfigModule#] }
internal class BedSheetModule {
	
	static Void bind(ServiceBinder binder) {
		binder.bindImpl(BedSheetService#)
		
		binder.bindImpl(Routes#)
		binder.bindImpl(RouteHandler#)
		binder.bindImpl(RouteMatcherSource#)
		binder.bindImpl(RouteMatcherArgImpl#)

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
		config.addMapped(ArgRoute#,		config.autobuild(RouteMatcherArgImpl#))
//		config.addMapped(PathMapRoute#,	config.autobuild(RouteMatcherPathMapImpl#))
//		config.addMapped(ExactRoute#,	config.autobuild(RouteMatcherExactImpl#))
	}

	@Contribute { serviceType=ResultProcessorSource# }
	static Void contributeResultProcessorSource(MappedConfig config) {
		config.addMapped(File#, 		config.autobuild(FileResultProcessor#))
		config.addMapped(JsonResult#, 	config.autobuild(JsonResultProcessor#))
		config.addMapped(TextResult#, 	config.autobuild(TextResultProcessor#))
	}
	
	@Contribute { serviceType=ErrProcessorSource# }
	static Void contributeErrProcessorSource(MappedConfig config) {
		config.addMapped(HttpStatusErr#,	config.autobuild(HttpStatusErrProcessor#))
		config.addMapped(Err#,				config.autobuild(DefaultErrProcessor#))
	}
	
	@Contribute { serviceType=FactoryDefaults# }
	static Void contributeFactoryDefaults(MappedConfig config) {
		config.addMapped(ConfigIds.pingInterval,			1sec)
		config.addMapped(ConfigIds.gzipDisabled,			false)
		config.addMapped(ConfigIds.gzipThreshold,			376)
		config.addMapped(ConfigIds.responseBufferThreshold,	8 * 1024)	// TODO: why not kB?
		
		config.addMapped(ConfigIds.corsAllowedOrigins,		"")
		config.addMapped(ConfigIds.corsExposeHeaders,		"")
		config.addMapped(ConfigIds.corsAllowCredentials,	false)
		config.addMapped(ConfigIds.corsAllowedMethods,		"GET, POST")
		config.addMapped(ConfigIds.corsAllowedHeaders,		"")
		config.addMapped(ConfigIds.corsMaxAge,				60min)
	}

	@Contribute { serviceType=ValueEncoderSource# }
	static Void contributeValueEncoderSource(MappedConfig config) {
		// wot no value encoders!? Aha! I see you're using fromStr() instead!
	}

	@Contribute { serviceType=GzipCompressible# }
	static Void contributeGzipCompressible(MappedConfig config) {
		// add some standard compressible mime types
		config.addMapped(MimeType("text/plain"),				true)
		config.addMapped(MimeType("text/css"),					true)
		config.addMapped(MimeType("text/tab-separated-values"),	true)
		config.addMapped(MimeType("text/html"),					true)
		config.addMapped(MimeType("text/javascript"),			true)
		config.addMapped(MimeType("text/xml"),					true)
		config.addMapped(MimeType("application/rss+xml"),		true)
		config.addMapped(MimeType("application/json"),			true)
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
