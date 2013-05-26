using afIoc
using web
using concurrent

@SubModule { modules=[ConfigModule#] }
internal class BedSheetModule {
	
	static Void bind(ServiceBinder binder) {
		binder.bindImpl(Router#)
		binder.bindImpl(RouteHandler#)
		binder.bindImpl(ResultProcessorSource#)

		binder.bindImpl(ValueEncoderSource#)
		binder.bindImpl(FileHandler#)

		binder.bindImpl(GzipCompressible#)
		
		binder.bindImpl(Request#).withScope(ServiceScope.perThread)
		binder.bindImpl(Response#).withScope(ServiceScope.perThread)
	}

	@Contribute { serviceType=ResultProcessorSource# }
	static Void configureResultProcessorSource(MappedConfig config) {
		config.addMapped(File#, 		config.autobuild(FileResultProcessor#))
		config.addMapped(JsonResult#, 	config.autobuild(JsonResultProcessor#))
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
	static Void configureGzipCompressible(OrderedConfig config) {
		// add some standard compressible mime types
		config.addUnordered(MimeType("text/plain"))
		config.addUnordered(MimeType("text/css"))
		config.addUnordered(MimeType("text/tab-separated-values"))
		config.addUnordered(MimeType("text/html"))
		config.addUnordered(MimeType("text/javascript"))
		config.addUnordered(MimeType("text/xml"))
		config.addUnordered(MimeType("application/rss+xml"))
		config.addUnordered(MimeType("application/json"))
	}
	
	// perInjection 'cos *we* shouldn't be caching these babies! 
	@Build { serviceId="WebReq"; scope=ServiceScope.perInjection }	
	private static WebReq buildRequest() {
		try return Actor.locals["web.req"]
		catch (NullErr e) 
			throw Err("No web request active in thread")
	}

	// perInjection 'cos *we* shouldn't be caching these babies! 
	@Build { serviceId="WebRes"; scope=ServiceScope.perInjection } 
	private static WebRes buildResponse() {
		try return Actor.locals["web.res"]
		catch (NullErr e)
			throw Err("No web request active in thread")
	}
}
