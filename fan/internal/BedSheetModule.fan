using afIoc
using web
using concurrent

@SubModule { modules=[ConfigModule#] }
internal class BedSheetModule {
	
	static Void bind(ServiceBinder binder) {
		
		binder.bindImpl(BedSheetService#)
		binder.bindImpl(RouteSource#)
		binder.bindImpl(RouteHandler#)

		binder.bindImpl(ValueEncoderSource#)
		binder.bindImpl(FileHandler#)

		binder.bindImpl(ResultProcessorSource#)
		binder.bindImpl(ErrProcessorSource#)

		binder.bindImpl(BrowserDetection#)
		binder.bindImpl(GzipCompressible#)
		
		binder.bindImpl(Request#).withScope(ServiceScope.perThread)
		binder.bindImpl(Response#).withScope(ServiceScope.perThread)
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
	
	@Contribute { serviceType=ConfigSource# } 
	static Void contributeConfigSource(MappedConfig config) {
		config.addMapped(ConfigIds.welcomePage,		`/index`)
		config.addMapped(ConfigIds.gzipDisabled,	false)
		config.addMapped(ConfigIds.gzipThreshold,	376)
	}

	@Contribute { serviceType=ValueEncoderSource# }
	static Void contributeValueEncoderSource(MappedConfig config) {
		// TODO: create more default encoders
		config.addMapped(Str#, 	StrValueEncoder())
		config.addMapped(Int#, 	IntValueEncoder())
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
	private static WebReq buildRequest() {
		try return Actor.locals["web.req"]
		catch (NullErr e) 
			throw Err("No web request active in thread")
	}

	@Build { serviceId="WebRes"; scope=ServiceScope.perThread } 
	private static WebRes buildResponse() {
		try return Actor.locals["web.res"]
		catch (NullErr e)
			throw Err("No web request active in thread")
	}
}
