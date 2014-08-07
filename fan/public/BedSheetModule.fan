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
		
		// Public services
		binder.bind(BedSheetServer#)
		binder.bind(GzipCompressible#)
		binder.bind(HttpSession#)
		binder.bind(HttpCookies#)
		binder.bind(HttpFlash#).withScope(ServiceScope.perThread)	// Because HttpFlash is thread scope, it needs a proxy to be injected into AppScope services
		binder.bind(BedSheetPages#)
		binder.bind(RequestLogMiddleware#)
		
		// Other services
		binder.bind(NotFoundPrinterHtml#)
		binder.bind(ErrPrinterHtml#)
		binder.bind(ErrPrinterStr#)
		binder.bind(FileAssetCache#)
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
	static Void contributeActorPools(Configuration config) {
		config["afBedSheet.system"] = ActorPool() { it.name = "afBedSheet.system" }
	}

	@Contribute { serviceType=MiddlewarePipeline# }
	static Void contributeMiddlewarePipeline(Configuration config) {
		config["afBedSheet.routes"] = config.autobuild(RoutesMiddleware#)
	}

	@Contribute { serviceId="HttpOutStream" }
	static Void contributeHttpOutStream(Configuration config) {
		config["afBedSheet.safeBuilder"] = HttpOutStreamSafeBuilder()					// inner
		config["afBedSheet.buffBuilder"] = config.autobuild(HttpOutStreamBuffBuilder#)	// middle - buff wraps safe
		config["afBedSheet.gzipBuilder"] = config.autobuild(HttpOutStreamGzipBuilder#)	// outer  - gzip wraps buff
	}

	@Contribute { serviceType=ResponseProcessors# }
	static Void contributeResponseProcessors(Configuration config, HttpStatusProcessors httpStatusProcessor) {
		config[Text#]		= config.autobuild(TextResponseProcessor#)
		config[File#]		= config.autobuild(FileResponseProcessor#)
		config[FileAsset#]	= config.autobuild(FileAssetResponseProcessor#)
		config[Redirect#]	= config.autobuild(RedirectResponseProcessor#)
		config[InStream#]	= config.autobuild(InStreamResponseProcessor#)
		config[MethodCall#]	= config.autobuild(MethodCallResponseProcessor#)
		config[HttpStatus#]	= httpStatusProcessor
	}

	@Contribute { serviceType=ValueEncoders# }
	static Void contributeValueEncoders(Configuration config) {
		// wot no value encoders!? Aha! I see you're using TypeCoercer as a backup!
	}

	@Contribute { serviceType=Routes# }
	static Void contributeFileHandlerRoutes(Configuration config, FileHandler fileHandler, ConfigSource iocSrc) {
		// @Deprecated placeholder
		config.addPlaceholder("afBedSheet.fileHandlerStart")
		config["afBedSheet.fileHandler"] = fileHandler.directoryMappings.map |dir, uri| {
			Route(uri + `***`, FileHandler#serviceRoute, "GET HEAD")	// Me like!
		}.vals
		// @Deprecated placeholder
		config.addPlaceholder("afBedSheet.fileHandlerEnd")
		
		podHandlerUrl := (Uri?) iocSrc.get(BedSheetConfigIds.podHandlerBaseUrl, Uri?#)
		if (podHandlerUrl != null)
			config["afBedSheet.podHandler"] = Route(podHandlerUrl + `***`, PodHandler#serviceRoute, "GET HEAD")	// Me like!
		else 
			config.addPlaceholder("afBedSheet.podHandler")
	}

	@Contribute { serviceType=PodHandler# }
	static Void contributePodHandlerWhitelist(Configuration config) {
		// by default, allow safe pod files to be served

		// html files
		config[".css"]	= "^.*\\.css\$"
		config[".htm"]	= "^.*\\.htm\$"
		config[".html"]	= "^.*\\.html\$"
		config[".js"]	= "^.*\\.js\$"
		
		// image files
		config[".bmp"]	= "^.*\\.bmp\$"
		config[".gif"]	= "^.*\\.gif\$"
		config[".ico"]	= "^.*\\.ico\$"
		config[".jpg"]	= "^.*\\.jpg\$"
		config[".png"]	= "^.*\\.png\$"
		
		// web font files
		config[".eot"]	= "^.*\\.eot\$"
		config[".ttf"]	= "^.*\\.ttf\$"
		config[".woff"]	= "^.*\\.woff\$"
		
		// other files
		config[".txt"]	= "^.*\\.txt\$"
	}
	
	@Contribute { serviceType=GzipCompressible# }
	static Void contributeGzipCompressible(Configuration config) {
		// add some standard compressible mime types
		config["application/atom+xml"]			= true
		config["application/json"]				= true
		config["application/rss+xml"]			= true
		config["application/xhtml+xml"]			= true
		config["text/css"]						= true
		config["text/html"]						= true
		config["text/javascript"]				= true
		config["text/plain"]					= true
		config["text/tab-separated-values"]		= true
		config["text/xml"]						= true

		// compress web fonts
		// see http://stackoverflow.com/questions/2871655/proper-mime-type-for-fonts#20723357
		config["application/vnd.ms-fontobject"]	= true	// eot
		config["application/font-sfnt"]			= true	// ttf, otf
		config["image/svg+xml"]					= true	// svg
		config["application/font-woff"]			= false	// woff files are already gzip compressed
	}

	@Contribute { serviceType=NotFoundPrinterHtml# }
	static Void contributeNotFoundPrinterHtml(Configuration config) {
		printer := (NotFoundPrinterHtmlSections) config.autobuild(NotFoundPrinterHtmlSections#)

		// these are all the sections you see on the 404 page
		config["afBedSheet.routeCode"]	= |WebOutStream out| { printer.printRouteCode		(out) }
		config["afBedSheet.routes"]		= |WebOutStream out| { printer.printBedSheetRoutes	(out) }
	}

	@Contribute { serviceType=ErrPrinterHtml# }
	static Void contributeErrPrinterHtml(Configuration config) {
		printer := (ErrPrinterHtmlSections) config.autobuild(ErrPrinterHtmlSections#)

		// these are all the sections you see on the Err500 page
		config["afBedSheet.causes"]					= |WebOutStream out, Err? err| { printer.printCauses				(out, err) }
		config["afBedSheet.availableValues"]		= |WebOutStream out, Err? err| { printer.printAvailableValues		(out, err) }
		config["afBedSheet.iocOperationTrace"]		= |WebOutStream out, Err? err| { printer.printIocOperationTrace		(out, err) }
		config["afBedSheet.srcCodeErrs"]			= |WebOutStream out, Err? err| { printer.printSrcCodeErrs			(out, err) }
		config["afBedSheet.stackTrace"]				= |WebOutStream out, Err? err| { printer.printStackTrace			(out, err) }
		config["afBedSheet.requestDetails"]			= |WebOutStream out, Err? err| { printer.printRequestDetails		(out, err) }
		config["afBedSheet.requestHeaders"]			= |WebOutStream out, Err? err| { printer.printRequestHeaders		(out, err) }
		config["afBedSheet.formParameters"]			= |WebOutStream out, Err? err| { printer.printFormParameters		(out, err) }
		config["afBedSheet.session"]				= |WebOutStream out, Err? err| { printer.printSession				(out, err) }
		config["afBedSheet.cookies"]				= |WebOutStream out, Err? err| { printer.printCookies				(out, err) }
		config["afBedSheet.locales"]				= |WebOutStream out, Err? err| { printer.printLocales				(out, err) }
		config["afBedSheet.iocConfig"]				= |WebOutStream out, Err? err| { printer.printIocConfig				(out, err) }
		config["afBedSheet.routes"]					= |WebOutStream out, Err? err| { printer.printBedSheetRoutes		(out, err) }
		config["afBedSheet.locals"]					= |WebOutStream out, Err? err| { printer.printLocals				(out, err) }
		config["afBedSheet.actorPools"]				= |WebOutStream out, Err? err| { printer.printActorPools			(out, err) }
		config["afBedSheet.fantomEnvironment"]		= |WebOutStream out, Err? err| { printer.printFantomEnvironment		(out, err) }
		config["afBedSheet.fantomIndexedProps"]		= |WebOutStream out, Err? err| { printer.printFantomIndexedProps	(out, err) }
		config["afBedSheet.fantomPods"]				= |WebOutStream out, Err? err| { printer.printFantomPods			(out, err) }
		config["afBedSheet.environmentVariables"]	= |WebOutStream out, Err? err| { printer.printEnvironmentVariables	(out, err) }
		config["afBedSheet.fantomDiagnostics"]		= |WebOutStream out, Err? err| { printer.printFantomDiagnostics		(out, err) }
	}

	@Contribute { serviceType=ErrPrinterStr# }
	static Void contributeErrPrinterStr(Configuration config) {
		printer := (ErrPrinterStrSections) config.autobuild(ErrPrinterStrSections#)
		
		// these are all the sections you see in the Err log
		config["afBedSheet.causes"]				=  |StrBuf out, Err? err| { printer.printCauses				(out, err) }
		config["afBedSheet.availableValues"]	=  |StrBuf out, Err? err| { printer.printAvailableValues	(out, err) }
		config["afBedSheet.iocOperationTrace"]	=  |StrBuf out, Err? err| { printer.printIocOperationTrace	(out, err) }
		config["afBedSheet.srcCodeErrs"]		=  |StrBuf out, Err? err| { printer.printSrcCodeErrs		(out, err) }		
		config["afBedSheet.stackTrace"]			=  |StrBuf out, Err? err| { printer.printStackTrace			(out, err) }
		config["afBedSheet.requestDetails"]		=  |StrBuf out, Err? err| { printer.printRequestDetails		(out, err) }
		config["afBedSheet.requestHeaders"]		=  |StrBuf out, Err? err| { printer.printRequestHeaders		(out, err) }
		config["afBedSheet.formParameters"]		=  |StrBuf out, Err? err| { printer.printFormParameters		(out, err) }
		config["afBedSheet.session"]			=  |StrBuf out, Err? err| { printer.printSession			(out, err) }
		config["afBedSheet.cookies"]			=  |StrBuf out, Err? err| { printer.printCookies			(out, err) }
		config["afBedSheet.locales"]			=  |StrBuf out, Err? err| { printer.printLocales			(out, err) }
		config["afBedSheet.iocConfig"]			=  |StrBuf out, Err? err| { printer.printIocConfig			(out, err) }
		config["afBedSheet.routes"]				=  |StrBuf out, Err? err| { printer.printRoutes				(out, err) }
		config["afBedSheet.locals"]				=  |StrBuf out, Err? err| { printer.printLocals				(out, err) }
		config["afBedSheet.actorPools"]			=  |StrBuf out, Err? err| { printer.printActorPools			(out, err) }
	}
	
	@Contribute { serviceType=FactoryDefaults# }
	static Void contributeFactoryDefaults(Configuration config, IocEnv iocEnv, RegistryMeta meta) {
		// honour the system config from Fantom-1.0.66 
		errTraceMaxDepth := (Int) (Env.cur.config(Env#.pod, "errTraceMaxDepth")?.toInt(10, false) ?: 0)
		bedSheetPort	 := meta["afBedSheet.port"]	?: 0
		
		config[BedSheetConfigIds.proxyPingInterval]				= 1sec
		config[BedSheetConfigIds.gzipDisabled]					= false
		config[BedSheetConfigIds.gzipThreshold]					= 376
		config[BedSheetConfigIds.responseBufferThreshold]		= 32 * 1024	// todo: why not kB?
		config[BedSheetConfigIds.defaultHttpStatusProcessor]	= config.registry.createProxy(DefaultHttpStatusProcessor#)
		config[BedSheetConfigIds.defaultErrProcessor]			= config.registry.createProxy(DefaultErrProcessor#)
		config[BedSheetConfigIds.noOfStackFrames]				= errTraceMaxDepth.max(75)	// big 'cos we hide a lot
		config[BedSheetConfigIds.srcCodeErrPadding]				= 5
		config[BedSheetConfigIds.disableWelcomePage]			= false
		config[BedSheetConfigIds.host]							= `http://localhost:${bedSheetPort}`

		config[BedSheetConfigIds.podHandlerBaseUrl]				= `/pods/`
		config[BedSheetConfigIds.fileAssetCacheControl]			= "public"	// don't assume we know how long to cache for - just say it's not user specific.
		
		config[BedSheetConfigIds.requestLogDir]					= null
		config[BedSheetConfigIds.requestLogFilenamePattern]		= "bedSheet-{YYYY-MM}.log"
		config[BedSheetConfigIds.requestLogFields]				= "date time c-ip cs(X-Real-IP) cs-method cs-uri-stem cs-uri-query sc-status time-taken cs(User-Agent) cs(Referer) cs(Cookie)"
	}
	
	@Contribute { serviceType=StackFrameFilter# }
	static Void contributeStackFrameFilter(Configuration config) {
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
	static Void contributeRegistryStartup(Configuration config, PlasticCompiler plasticCompiler, ConfigSource configSrc) {
		config["afBedSheet.srcCodePadding"] = |->| {
			plasticCompiler.srcCodePadding = configSrc.get(BedSheetConfigIds.srcCodeErrPadding, Int#)
		}

		config["afBedSheet.validateHost"] = |->| {
			host := (Uri) configSrc.get(BedSheetConfigIds.host, Uri#)
			validateHost(host)
		}

		config.remove("afIoc.logServices", "afBedSheet.logServices")
	}

	@Contribute { serviceType=RegistryShutdown# }
	static Void contributeRegistryShutdown(Configuration config, RequestLogMiddleware logMiddleware) {
		config["afBedSheet.requestLogFilter"] = |->| {
			logMiddleware.shutdown
		}
	}
	
	internal static Void validateHost(Uri host) {
		if (host.scheme == null || host.host == null)
			throw BedSheetErr(BsErrMsgs.startup_hostMustHaveSchemeAndHost(BedSheetConfigIds.host, host))
		if (!host.pathStr.isEmpty && host.pathStr != "/")
			throw BedSheetErr(BsErrMsgs.startup_hostMustNotHavePath(BedSheetConfigIds.host, host))		
	}

	private static Obj makeDelegateChain(DelegateChainBuilder[] delegateBuilders, Obj service) {
		delegateBuilders.reduce(service) |Obj delegate, DelegateChainBuilder builder -> Obj| { 		
			return builder.build(delegate)
		}
	}
}
