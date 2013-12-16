using web
using afIoc
using afIocEnv::IocEnvModule
using concurrent::Actor
using afPlastic::PlasticCompiler
using afIocConfig::FactoryDefaults
using afIocConfig::IocConfigSource
using afIocConfig::IocConfigModule

** The [afIoc]`http://repo.status302.com/doc/afIoc/#overview` module class.
** 
** This class is public so it may be referenced explicitly in test code.
@SubModule { modules=[IocConfigModule#, IocEnvModule#] }
const class BedSheetModule {
	// IocConfigModule is referenced explicitly so there is no dicking about with transitive 
	// dependencies on BedSheet startup
	
	static Void bind(ServiceBinder binder) {
		
		// Utils
		binder.bindImpl(PipelineBuilder#)

		// Routing
		binder.bindImpl(Routes#)
		binder.bindImpl(ValueEncoders#)
		
		// Request handlers
		binder.bindImpl(FileHandler#).withoutProxy				// has default method args
		binder.bindImpl(PodHandler#).withoutProxy				// has default method args

		// Collections (services with contributions)
		binder.bindImpl(ResponseProcessors#)
		binder.bindImpl(ErrProcessors#)
		binder.bindImpl(HttpStatusProcessors#) 
		
		// Other services
		binder.bindImpl(GzipCompressible#)
		binder.bindImpl(ErrPrinterHtml#)
		binder.bindImpl(ErrPrinterStr#)
		binder.bindImpl(HttpSession#)
		binder.bindImpl(HttpFlash#).withScope(ServiceScope.perThread)	// Because HttpFlash is thread scope, it needs a proxy to be injected into AppScope services
		binder.bindImpl(BedSheetPage#)

		// TODO: afIoc-1.5 : use createProxy() instead
		binder.bindImpl(DefaultHttpStatusProcessor#)
		binder.bindImpl(DefaultErrProcessor#)
	}

	@Build { serviceId="BedSheetMetaData" }
	static BedSheetMetaData buildBedSheetMetaData(RegistryOptions options) {
		if (!options.options.containsKey("bedSheetMetaData"))
			throw BedSheetErr(BsErrMsgs.bedSheetMetaDataNotInOptions)
		return options.options["bedSheetMetaData"] 
	}

	@Build { serviceId="HttpPipeline"; disableProxy=true }	// no need for a proxy, you don't advice the pipeline, you contribute to it!
	static HttpPipeline buildHttpPipeline(HttpPipelineFilter[] filters, PipelineBuilder bob, Registry reg) {
		terminator := reg.autobuild(HttpPipelineTerminator#)
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
		conf.addOrdered("HttpErrFilter", 		conf.autobuild(HttpErrFilter#), 	["before: BedSheetFilters", "before: HttpFlashFilter"])		
		conf.addOrdered("HttpFlashFilter", 		conf.autobuild(HttpFlashFilter#), 	["before: BedSheetFilters"])
		conf.addPlaceholder("BedSheetFilters")
		conf.addOrdered("HttpRouteFilter", 		conf.autobuild(HttpRouteFilter#), 	["after: BedSheetFilters"])
	}

	@Contribute { serviceId="HttpOutStream" }
	static Void contributeHttpOutStream(OrderedConfig conf) {
		conf.addOrdered("HttpOutStreamBuffBuilder", 	conf.autobuild(HttpOutStreamBuffBuilder#), ["before: HttpOutStreamGzipBuilder"])		
		conf.addOrdered("HttpOutStreamGzipBuilder", 	conf.autobuild(HttpOutStreamGzipBuilder#))
	}

	@Contribute { serviceType=ResponseProcessors# }
	static Void contributeResponseProcessors(MappedConfig conf, HttpStatusProcessors httpStatusProcessor) {
		conf[Text#]				= conf.autobuild(TextResponseProcessor#)
		conf[File#]				= conf.autobuild(FileResponseProcessor#)
		conf[Redirect#]			= conf.autobuild(RedirectResponseProcessor#)
		conf[InStream#]			= conf.autobuild(InStreamResponseProcessor#)
		conf[MethodCall#]		= conf.autobuild(MethodCallResponseProcessor#)
		conf[HttpStatus#]		= httpStatusProcessor
	}

	@Contribute { serviceType=ErrProcessors# }
	static Void contributeErrProcessors(MappedConfig conf) {
		conf[HttpStatusErr#]	= conf.autobuild(HttpStatusErrProcessor#)
	}

	@Contribute { serviceType=FactoryDefaults# }
	static Void contributeFactoryDefaults(MappedConfig conf, DefaultHttpStatusProcessor defaultHttpStatus, DefaultErrProcessor defaultErr) {
		conf[BedSheetConfigIds.proxyPingInterval]				= 1sec
		conf[BedSheetConfigIds.gzipDisabled]					= false
		conf[BedSheetConfigIds.gzipThreshold]					= 376
		conf[BedSheetConfigIds.responseBufferThreshold]			= 32 * 1024	// TODO: why not kB?
		conf[BedSheetConfigIds.defaultHttpStatusProcessor]		= defaultHttpStatus
		conf[BedSheetConfigIds.defaultErrProcessor]				= defaultErr
		conf[BedSheetConfigIds.noOfStackFrames]					= 50
		conf[BedSheetConfigIds.srcCodeErrPadding]				= 5

		conf[BedSheetConfigIds.httpRequestLogDir]				= null
		conf[BedSheetConfigIds.httpRequestLogFilenamePattern]	= "afBedSheet-{YYYY-MM}.log"
		conf[BedSheetConfigIds.httpRequestLogFields]			= "date time c-ip cs(X-Real-IP) cs-method cs-uri-stem cs-uri-query sc-status time-taken cs(User-Agent) cs(Referer) cs(Cookie)"
	}

	@Contribute { serviceType=ValueEncoders# }
	static Void contributeValueEncoders(MappedConfig config) {
		// wot no value encoders!? Aha! I see you're using fromStr() instead!
	}

	@Contribute { serviceType=DependencyProviderSource# } 
	static Void contributeDependencyProviderSource(OrderedConfig config) {
		// this is a copy of IocConfig's ConfigProvider so we can use BedSheet's @Config
		config.add(config.autobuild(ConfigProvider2#))
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
	
	@Contribute { serviceType=ErrPrinterHtml# }
	static Void contributeErrPrinterHtml(OrderedConfig config) {
		printer := (ErrPrinterHtmlSections) config.autobuild(ErrPrinterHtmlSections#)

		// these are all the sections you see on the Err500 page
		config.addOrdered("Causes",					|WebOutStream out, Err? err| { printer.printCauses					(out, err) })
		config.addOrdered("AvailableValues",		|WebOutStream out, Err? err| { printer.printAvailableValues			(out, err) })
		config.addOrdered("IocOperationTrace",		|WebOutStream out, Err? err| { printer.printIocOperationTrace		(out, err) })
		config.addOrdered("SrcCodeErrs", 			|WebOutStream out, Err? err| { printer.printSrcCodeErrs				(out, err) })
		config.addOrdered("StackTrace",				|WebOutStream out, Err? err| { printer.printStackTrace				(out, err) })
		config.addOrdered("RequestDetails",			|WebOutStream out, Err? err| { printer.printRequestDetails			(out, err) })
		config.addOrdered("RequestHeaders",			|WebOutStream out, Err? err| { printer.printRequestHeaders			(out, err) })
		config.addOrdered("FormParameters",			|WebOutStream out, Err? err| { printer.printFormParameters			(out, err) })
		config.addOrdered("Session",				|WebOutStream out, Err? err| { printer.printSession					(out, err) })
		config.addOrdered("Cookies",				|WebOutStream out, Err? err| { printer.printCookies					(out, err) })
		config.addOrdered("Locales",				|WebOutStream out, Err? err| { printer.printLocales					(out, err) })
		config.addOrdered("Locals",					|WebOutStream out, Err? err| { printer.printLocals					(out, err) })
		config.addOrdered("FantomEnvironment",		|WebOutStream out, Err? err| { printer.printFantomEnvironment		(out, err) })
		config.addOrdered("FantomIndexedProps",		|WebOutStream out, Err? err| { printer.printFantomIndexedProps		(out, err) })
		config.addOrdered("EnvironmentVariables",	|WebOutStream out, Err? err| { printer.printEnvironmentVariables	(out, err) })
		config.addOrdered("FantomDiagnostics",		|WebOutStream out, Err? err| { printer.printFantomDiagnostics		(out, err) })
	}

	@Contribute { serviceType=ErrPrinterStr# }
	static Void contributeErrPrinterStr(OrderedConfig config) {
		printer := (ErrPrinterStrSections) config.autobuild(ErrPrinterStrSections#)
		
		// these are all the sections you see on the Err log
		config.addOrdered("Causes",					|StrBuf out, Err? err| { printer.printCauses			(out, err) })
		config.addOrdered("AvailableValues",		|StrBuf out, Err? err| { printer.printAvailableValues	(out, err) })
		config.addOrdered("IocOperationTrace",		|StrBuf out, Err? err| { printer.printIocOperationTrace	(out, err) })
		config.addOrdered("SrcCodeErrs", 			|StrBuf out, Err? err| { printer.printSrcCodeErrs		(out, err) })		
		config.addOrdered("StackTrace",				|StrBuf out, Err? err| { printer.printStackTrace		(out, err) })
		config.addOrdered("RequestDetails",			|StrBuf out, Err? err| { printer.printRequestDetails	(out, err) })
		config.addOrdered("RequestHeaders",			|StrBuf out, Err? err| { printer.printRequestHeaders	(out, err) })
		config.addOrdered("FormParameters",			|StrBuf out, Err? err| { printer.printFormParameters	(out, err) })
		config.addOrdered("Session",				|StrBuf out, Err? err| { printer.printSession			(out, err) })
		config.addOrdered("Cookies",				|StrBuf out, Err? err| { printer.printCookies			(out, err) })
		config.addOrdered("Locales",				|StrBuf out, Err? err| { printer.printLocales			(out, err) })
		config.addOrdered("Locals",					|StrBuf out, Err? err| { printer.printLocals			(out, err) })
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
	
	@Contribute { serviceType=RegistryStartup# }
	static Void contributeRegistryStartup(OrderedConfig conf, PlasticCompiler plasticCompiler, IocConfigSource configSrc) {
		conf.add |->| {
			plasticCompiler.srcCodePadding = configSrc.getCoerced(BedSheetConfigIds.srcCodeErrPadding, Int#)
		}
	}
	
	private static Obj makeDelegateChain(DelegateChainBuilder[] delegateBuilders, Obj service) {
		delegateBuilders.reduce(service) |Obj delegate, DelegateChainBuilder builder -> Obj| { 		
			return builder.build(delegate) 
		}
	}
}
