using afIoc
using web
using concurrent

@SubModule { modules=[ConfigModule#] }
class BedSheetModule {
	
	static Void bind(ServiceBinder binder) {
		binder.bindImpl(Router#)
		binder.bindImpl(ResultProcessorSource#)
		binder.bindImpl(FileServer#)
		binder.bindImpl(Request#)
	}
	
	@Contribute { serviceType=ResultProcessorSource# }
	static Void configureResultProcessorSource(MappedConfig config) {
		config.addMapped(File#, config.autobuild(FileResultProcessor#))
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

	@Deprecated 
	@Build { serviceId="Route"; scope=ServiceScope.perInjection } 
	private static Route buildRoute() {
		k:=Actor.locals.keys
		Env.cur.err.printLine(k)
		try return Actor.locals["BedSheetWebMod.0001.route"]
		catch (NullErr e)
			throw Err("No web request active in thread")
	}
}
