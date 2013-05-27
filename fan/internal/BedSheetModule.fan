using afIoc
using web
using concurrent

@SubModule { modules=[ConfigModule#] }
internal class BedSheetModule {
	
	static Void bind(ServiceBinder binder) {
		binder.bindImpl(BedSheetService#)
		binder.bindImpl(Router#)
		binder.bindImpl(RouteHandler#)
		binder.bindImpl(ResultProcessorSource#)

		binder.bindImpl(ValueEncoderSource#)
		binder.bindImpl(FileHandler#)

		binder.bindImpl(ErrHandlerSource#)

		binder.bindImpl(GzipCompressible#)
		
		binder.bindImpl(Request#).withScope(ServiceScope.perThread)
		binder.bindImpl(Response#).withScope(ServiceScope.perThread)
	}

	@Contribute { serviceType=ResultProcessorSource# }
	static Void configureResultProcessorSource(MappedConfig config) {
		config.addMapped(File#, 		config.autobuild(FileResultProcessor#))
		config.addMapped(JsonResult#, 	config.autobuild(JsonResultProcessor#))
		config.addMapped(TextResult#, 	config.autobuild(TextResultProcessor#))
	}
	
	@Contribute { serviceType=ErrHandlerSource# }
	static Void configureErrHandlerSource(MappedConfig config) {
		config.addMapped(HttpStatusErr#,	config.autobuild(HttpStatusErrHandler#))
	}
	
	
	
	@Contribute { serviceType=ConfigSource# } 
	static Void configureConfigSource(MappedConfig config) {
//		config.addMapped("yahoo.WebSearchUri", 		`http://uk.search.yahoo.com/search`)
	}
	
	@Contribute { serviceType=ValueEncoderSource# }
	static Void configureValueEncoderSource(MappedConfig config) {
		// TODO: create more default encoders
		config.addMapped(Str#, 	StrValueEncoder())
		config.addMapped(Int#, 	IntValueEncoder())
	}
	
	@Contribute { serviceType=GzipCompressible# }
	static Void configureGzipCompressible(MappedConfig config) {
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
	
	// perInjection 'cos *we* shouldn't be caching these babies! 
	@Build { serviceId="WebReq"; scope=ServiceScope.perThread }	
	private static WebReq buildRequest() {
		try return Actor.locals["web.req"]
		catch (NullErr e) 
			throw Err("No web request active in thread")
	}

	// perInjection 'cos *we* shouldn't be caching these babies! 
	@Build { serviceId="WebRes"; scope=ServiceScope.perThread } 
	private static WebRes buildResponse() {
		try return Actor.locals["web.res"]
		catch (NullErr e)
			throw Err("No web request active in thread")
	}
}
