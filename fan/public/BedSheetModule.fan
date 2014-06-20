using web
using afIoc
using afIocEnv
using afIocConfig
using concurrent::Actor
using concurrent::ActorPool
using afPlastic::PlasticCompiler

** The [Ioc]`http://www.fantomfactory.org/pods/afIoc` module class.
** 
** This class is public so it may be referenced explicitly in test code.
@NoDoc
@SubModule { modules=[IocConfigModule#, IocEnvModule#] }
const class BedSheetModule {
	// IocConfigModule is referenced explicitly so there is no dicking about with transitive 
	// dependencies on BedSheet startup
	
	static Void bind(ServiceBinder binder) {
		
		// Utils
		binder.bind(PipelineBuilder#)
		binder.bind(StackFrameFilter#)

		// Request handlers
		binder.bind(FileHandler#)
		binder.bind(PodHandler#)

		// Collections (services with contributions)
		binder.bind(ResponseProcessors#)
		binder.bind(ErrProcessors#)
		binder.bind(HttpStatusProcessors#) 
		binder.bind(Routes#)
		binder.bind(ValueEncoders#)
		
		// Other services
		binder.bind(GzipCompressible#)
		binder.bind(NotFoundPrinterHtml#)
		binder.bind(ErrPrinterHtml#)
		binder.bind(ErrPrinterStr#)
		binder.bind(HttpSession#)
		binder.bind(HttpCookies#)
		binder.bind(HttpFlash#).withScope(ServiceScope.perThread)	// Because HttpFlash is thread scope, it needs a proxy to be injected into AppScope services
		binder.bind(BedSheetPages#)
		binder.bind(RequestLogMiddleware#)
		binder.bind(FileMetaCache#)
	}

	@Build { serviceId="BedSheetMetaData" }
	static BedSheetMetaData buildBedSheetMetaData(RegistryMeta options) {
		if (!options.options.containsKey("afBedSheet.metaData"))
			throw BedSheetErr(BsErrMsgs.bedSheetMetaDataNotInOptions)
		return options.options["afBedSheet.metaData"] 
	}

	// No need for a proxy, you don't advice the pipeline, you contribute to it!
	// App scope 'cos the pipeline has no state - the pipeline is welded / hardcoded together!
	@Build { serviceId="MiddlewarePipeline"; disableProxy=true }
	static MiddlewarePipeline buildMiddlewarePipeline(Middleware[] userMiddleware, PipelineBuilder bob, Registry reg) {
		// hardcode BedSheet default middleware
		middleware := Middleware[
			reg.autobuild(CleanupMiddleware#),
			reg.autobuild(ErrMiddleware#),
			reg.autobuild(FlashMiddleware#),
			reg.serviceById(RequestLogMiddleware#.qname)
		].addAll(userMiddleware)
		terminator := reg.autobuild(MiddlewareTerminator#)
		return bob.build(MiddlewarePipeline#, Middleware#, middleware, terminator)
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

	@Contribute { serviceType=ActorPools# }
	static Void contributeActorPools(MappedConfig config) {
		config["afBedSheet.system"] = ActorPool() { it.name = "afBedSheet.system" }
	}

	@Contribute { serviceType=MiddlewarePipeline# }
	static Void contributeMiddlewarePipeline(OrderedConfig conf) {
		conf.addOrdered("Routes", conf.autobuild(RoutesMiddleware#))
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

	@Contribute { serviceType=ValueEncoders# }
	static Void contributeValueEncoders(MappedConfig config) {
		// wot no value encoders!? Aha! I see you're using TypeCoercer as a backup!
	}

	@Contribute { serviceType=Routes# }
	static Void contributeFileHandlerRoutes(OrderedConfig conf, FileHandler fileHandler) {
		conf.addPlaceholder("FileHandlerStart")
		fileHandler.directoryMappings.each |dir, uri| {
			conf.add(Route(uri + `***`, FileHandler#service, "GET HEAD"))	// Me like!
		}
		conf.addPlaceholder("FileHandlerEnd")
	}
	
	@Contribute { serviceType=GzipCompressible# }
	static Void contributeGzipCompressible(MappedConfig conf) {
		// add some standard compressible mime types
		conf["application/atom+xml"]		= true
		conf["application/json"]			= true
		conf["application/rss+xml"]			= true
		conf["application/xhtml+xml"]		= true
		conf["text/css"]					= true
		conf["text/html"]					= true
		conf["text/javascript"]				= true
		conf["text/plain"]					= true
		conf["text/tab-separated-values"]	= true
		conf["text/xml"]					= true

		// compress web fonts
		// see http://stackoverflow.com/questions/2871655/proper-mime-type-for-fonts#20723357
		conf["application/vnd.ms-fontobject "]	= true	// eot
		conf["application/font-sfnt"]			= true	// ttf, otf
		conf["image/svg+xml"]					= true	// svg
		conf["application/font-woff"]			= false	// woff files are already gzip compressed
	}

	@Contribute { serviceType=NotFoundPrinterHtml# }
	static Void contributeNotFoundPrinterHtml(OrderedConfig config) {
		printer := (NotFoundPrinterHtmlSections) config.autobuild(NotFoundPrinterHtmlSections#)

		// these are all the sections you see on the 404 page
		config.addOrdered("RouteCode",				|WebOutStream out| { printer.printRouteCode			(out) })
		config.addOrdered("Routes",					|WebOutStream out| { printer.printBedSheetRoutes	(out) })
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
		config.addOrdered("IocConfig",				|WebOutStream out, Err? err| { printer.printIocConfig				(out, err) })
		config.addOrdered("Routes",					|WebOutStream out, Err? err| { printer.printBedSheetRoutes			(out, err) })
		config.addOrdered("Locals",					|WebOutStream out, Err? err| { printer.printLocals					(out, err) })
		config.addOrdered("ActorPools",				|WebOutStream out, Err? err| { printer.printActorPools				(out, err) })
		config.addOrdered("FantomEnvironment",		|WebOutStream out, Err? err| { printer.printFantomEnvironment		(out, err) })
		config.addOrdered("FantomIndexedProps",		|WebOutStream out, Err? err| { printer.printFantomIndexedProps		(out, err) })
		config.addOrdered("FantomPods",				|WebOutStream out, Err? err| { printer.printFantomPods				(out, err) })
		config.addOrdered("EnvironmentVariables",	|WebOutStream out, Err? err| { printer.printEnvironmentVariables	(out, err) })
		config.addOrdered("FantomDiagnostics",		|WebOutStream out, Err? err| { printer.printFantomDiagnostics		(out, err) })
	}

	@Contribute { serviceType=ErrPrinterStr# }
	static Void contributeErrPrinterStr(OrderedConfig config) {
		printer := (ErrPrinterStrSections) config.autobuild(ErrPrinterStrSections#)
		
		// these are all the sections you see in the Err log
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
		config.addOrdered("IocConfig",				|StrBuf out, Err? err| { printer.printIocConfig			(out, err) })
		config.addOrdered("Routes",					|StrBuf out, Err? err| { printer.printRoutes			(out, err) })
		config.addOrdered("Locals",					|StrBuf out, Err? err| { printer.printLocals			(out, err) })
		config.addOrdered("ActorPools",				|StrBuf out, Err? err| { printer.printActorPools		(out, err) })
	}
	
	@Contribute { serviceType=FactoryDefaults# }
	static Void contributeFactoryDefaults(MappedConfig conf, Registry reg, IocEnv iocEnv, BedSheetMetaData meta) {
		// honour the system config from Fantom-1.0.66 
		errTraceMaxDepth := (Int) (Env.cur.config(Env#.pod, "errTraceMaxDepth")?.toInt(10, false) ?: 0)

		conf[BedSheetConfigIds.proxyPingInterval]			= 1sec
		conf[BedSheetConfigIds.gzipDisabled]				= false
		conf[BedSheetConfigIds.gzipThreshold]				= 376
		conf[BedSheetConfigIds.responseBufferThreshold]		= 32 * 1024	// todo: why not kB?
		conf[BedSheetConfigIds.defaultHttpStatusProcessor]	= reg.createProxy(DefaultHttpStatusProcessor#)
		conf[BedSheetConfigIds.defaultErrProcessor]			= reg.createProxy(DefaultErrProcessor#)
		conf[BedSheetConfigIds.noOfStackFrames]				= errTraceMaxDepth.max(75)	// big 'cos we hide a lot
		conf[BedSheetConfigIds.srcCodeErrPadding]			= 5
		conf[BedSheetConfigIds.disableWelcomePage]			= false
		conf[BedSheetConfigIds.host]						= "http://localhost:${meta.port}".toUri	// Stoopid F4 can't interpolate URIs with method params!!
		
		conf[BedSheetConfigIds.requestLogDir]				= null
		conf[BedSheetConfigIds.requestLogFilenamePattern]	= "bedSheet-{YYYY-MM}.log"
		conf[BedSheetConfigIds.requestLogFields]			= "date time c-ip cs(X-Real-IP) cs-method cs-uri-stem cs-uri-query sc-status time-taken cs(User-Agent) cs(Referer) cs(Cookie)"
	}
	
	@Contribute { serviceType=StackFrameFilter# }
	static Void contributeStackFrameFilter(OrderedConfig config) {
		// remove meaningless and boring stack frames
		
		// Core Fantom libs
		config.add("^concurrent::Actor._dispatch.*\$")
		config.add("^concurrent::Actor._send.*\$")
		config.add("^concurrent::Actor._work.*\$")
		config.add("^concurrent::ThreadPool\\\$Worker.run.*\$")
		
		// Core Alien-Factory libs
		config.add("^afIoc::.*\$")
		config.add("^afBedSheet::.*\$")
		
		// Java code
		config.add("^fan.sys.Method\\\$MethodFunc\\..*\$")
		config.add("^fan.sys.Method\\..*\$")
		config.add("^fan.sys.FanObj.doTrap.*\$")
		config.add("^fan.sys.FanObj.trap.*\$")
		config.add("^fan.sys.Func\\\$Indirect0.call.*\$")
		config.add("^java.lang.reflect..*\$")
	}
	
	@Contribute { serviceType=RegistryStartup# }
	static Void contributeRegistryStartup(OrderedConfig conf, PlasticCompiler plasticCompiler, IocConfigSource configSrc) {
		conf.add |->| {
			plasticCompiler.srcCodePadding = configSrc.get(BedSheetConfigIds.srcCodeErrPadding, Int#)
		}
		conf.remove("afIoc.showServices", "afBedSheet.showServices")
	}

	@Contribute { serviceType=RegistryShutdown# }
	static Void contributeRegistryShutdown(OrderedConfig conf, RequestLogMiddleware logMiddleware) {
		conf.addOrdered("afBedSheet.requestLogFilter") |->| {
			logMiddleware.shutdown
		}
	}
	
	private static Obj makeDelegateChain(DelegateChainBuilder[] delegateBuilders, Obj service) {
		delegateBuilders.reduce(service) |Obj delegate, DelegateChainBuilder builder -> Obj| { 		
			return builder.build(delegate)
		}
	}
}
