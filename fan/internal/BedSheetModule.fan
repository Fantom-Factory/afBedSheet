using afIoc
using web
using concurrent

@SubModule { modules=[ConfigModule#] }
internal class BedSheetModule {
	
	static Void bind(ServiceBinder binder) {
		binder.bindImpl(Routes#)
		binder.bindImpl(RouteMatchers#).withoutProxy
		binder.bindImpl(ReqestHandlerInvoker#)

		binder.bindImpl(ValueEncoders#)
		binder.bindImpl(FileHandler#)

		binder.bindImpl(HttpStatusProcessors#)
		binder.bindImpl(ResponseProcessors#)
		binder.bindImpl(ErrProcessors#)

		binder.bindImpl(MoustacheTemplates#).withoutProxy	// has default method args
		binder.bindImpl(BrowserDetection#)
		binder.bindImpl(GzipCompressible#)
		binder.bindImpl(ErrPrinter#)
		binder.bindImpl(BedSheetPage#)
		
		binder.bindImpl(HttpSession#)

		binder.bindImpl(CorsHandler#).withoutProxy				// has default method args
		binder.bindImpl(IeAjaxCacheBustingFilter#).withoutProxy	// has default method args
		binder.bindImpl(HttpRequestLogFilter#).withoutProxy		// has default method args
		
		// as it's used in FactoryDefaults we need to proxy it, because it needs MoustacheTemplates 
		// (non proxy-iable) which needs @Config which needs FactoryDefaults...!!!
		binder.bindImpl(HttpStatusPageDefault#)
	}

	@Build { serviceId="HttpPipeline"; disableProxy=true }	// no need for a proxy, you don't advice the pipeline, you contribute to it!
	static HttpPipeline buildHttpPipeline(HttpPipelineFilter[] filters, PipelineBuilder bob, Registry reg) {
		terminator := reg.autobuild(HttpRouteService#)
		return bob.build(HttpPipeline#, HttpPipelineFilter#, filters, terminator)
	}

	@Build { serviceId="HttpRequest" }
	static HttpRequest buildHttpRequest(DelegateChainBuilder[] builders, Registry reg) {
		makeDelegateChain(builders, reg.autobuild(HttpRequestImpl#))
	}

	@Build { serviceId="HttpResponse" }
	static HttpResponse buildHttpResponse(DelegateChainBuilder[] builders, Registry reg) {
		makeDelegateChain(builders, reg.autobuild(HttpResponseImpl#))
	}

	@Build { serviceId="HttpOutStream"; disableProxy=true; scope=ServiceScope.perThread }
	static OutStream buildHttpOutStream(DelegateChainBuilder[] builders, Registry reg) {
		makeDelegateChain(builders, reg.autobuild(WebResOutProxy#))
	}
	
	@Contribute { serviceType=HttpPipeline# }
	static Void contributeHttpPipeline(OrderedConfig conf) {
		conf.addOrdered("HttpCleanupFilter", 	conf.autobuild(HttpCleanupFilter#), ["before: BedSheetFilters", "before: HttpErrFilter"])
		conf.addOrdered("HttpErrFilter", 		conf.autobuild(HttpErrFilter#), 	["before: BedSheetFilters"])		
		conf.addPlaceholder("BedSheetFilters")
	}

	@Contribute { serviceId="HttpOutStream" }
	static Void contributeHttpOutStream(OrderedConfig conf) {
		conf.addOrdered("HttpOutStreamBuffBuilder", 	conf.autobuild(HttpOutStreamBuffBuilder#), ["before: HttpOutStreamGzipBuilder"])		
		conf.addOrdered("HttpOutStreamGzipBuilder", 	conf.autobuild(HttpOutStreamGzipBuilder#))
	}

	@Contribute { serviceType=RouteMatchers# }
	static Void contributeRouteMatchers(MappedConfig conf) {
		conf[Route#] 			= conf.autobuild(RouteMatcherImpl#)
	}

	@Contribute { serviceType=ResponseProcessors# }
	static Void contributeResponseProcessors(MappedConfig conf, HttpStatusProcessors httpStatusProcessor) {
		conf[File#]				= conf.autobuild(FileResponseProcessor#)
		conf[TextResponse#]		= conf.autobuild(TextResponseProcessor#)
		conf[Redirect#]			= conf.autobuild(RedirectResponseProcessor#)
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
	static Void contributeFactoryDefaults(MappedConfig conf, HttpStatusPageDefault defaultStatusPage) {
		conf[ConfigIds.proxyPingInterval]				= 1sec
		conf[ConfigIds.gzipDisabled]					= false
		conf[ConfigIds.gzipThreshold]					= 376
		conf[ConfigIds.responseBufferThreshold]			= 32 * 1024	// TODO: why not kB?
		conf[ConfigIds.httpStatusDefaultPage]			= defaultStatusPage
		conf[ConfigIds.noOfStackFrames]					= 50
		conf[ConfigIds.moustacheTemplateTimeout]		= 10sec
		conf[ConfigIds.errPageDisabled]					= false
				
		conf[ConfigIds.httpRequestLogDir]				= null
		conf[ConfigIds.httpRequestLogFilenamePattern]	= "afBedSheet-{YYYY-MM}.log"
		conf[ConfigIds.httpRequestLogFields]			= "date time c-ip cs(X-Real-IP) cs-method cs-uri-stem cs-uri-query sc-status time-taken cs(User-Agent) cs(Referer) cs(Cookie)"
		
		conf[ConfigIds.corsAllowedOrigins]				= "*"
		conf[ConfigIds.corsExposeHeaders]				= null
		conf[ConfigIds.corsAllowCredentials]			= false
		conf[ConfigIds.corsAllowedMethods]				= "GET, POST"
		conf[ConfigIds.corsAllowedHeaders]				= null
		conf[ConfigIds.corsMaxAge]						= 60min
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
	
	private static Obj makeDelegateChain(DelegateChainBuilder[] delegateBuilders, Obj service) {
		delegateBuilders.reduce(service) |Obj delegate, DelegateChainBuilder builder -> Obj| { 		
			return builder.build(delegate) 
		}
	}
}
