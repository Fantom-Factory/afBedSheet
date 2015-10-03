using web
using afIoc3
using afIocEnv
using afIocConfig
using concurrent::Actor
using concurrent::ActorPool

** The [Ioc]`http://www.fantomfactory.org/pods/afIoc` module class.
** 
** This class is public so it may be referenced explicitly in test code.
@NoDoc
@SubModule { modules=[ConfigModule#, BedSheetEnvModule#] }
const class BedSheetModule {
	// IocConfigModule is referenced explicitly so there is no dicking about with transitive 
	// dependencies on BedSheet startup
	
	static Void defineServices(RegistryBuilder defs) {

		// Route handlers
		defs.addServiceType(FileHandler#)			.withRootScope
		defs.addServiceType(PodHandler#)			.withRootScope

		// Collections (services with contributions)
		defs.addServiceType(ResponseProcessors#)	.withRootScope
		defs.addServiceType(ErrResponses#)			.withRootScope
		defs.addServiceType(HttpStatusResponses#)	.withRootScope
		defs.addServiceType(Routes#)				.withRootScope
		defs.addServiceType(ValueEncoders#)			.withRootScope
		
		// Public services - root
		defs.addServiceType(BedSheetServer#)		.withRootScope
		defs.addServiceType(GzipCompressible#)		.withRootScope
		defs.addServiceType(BedSheetPages#)			.withRootScope
		
		// Public services - request
		defs.addServiceType(RequestLoggers#)		.withRootScope
		defs.addServiceType(HttpSession#)			.withRootScope
		defs.addServiceType(HttpCookies#)			.withRootScope

		// Other services - root
		defs.addServiceType(StackFrameFilter#)		.withRootScope
		
		// Other services - request
		defs.addServiceType(NotFoundPrinterHtml#)	.withRootScope
		defs.addServiceType(ErrPrinterHtml#)		.withRootScope
		defs.addServiceType(ErrPrinterStr#)			.withRootScope
		defs.addServiceType(ClientAssetProducers#)	.withRootScope
		defs.addServiceType(ClientAssetCache#)		.withRootScope
		defs.addServiceType(ObjCache#)				.withRootScope

		defs.addServiceType(ActorPools#)			.withRootScope
		defs.addServiceType(ThreadLocalManager#)	.withRootScope

		defs.addServiceType(RequestState#)			.withScope("request")
	}

	// No need for a proxy, you don't advice the pipeline, you contribute to it!
	// App scope 'cos the pipeline has no state - the pipeline is welded / hardcoded together!
	@Build { scopes=["root"] }
	static MiddlewarePipeline buildMiddlewarePipeline(Middleware[] userMiddleware, Scope scope, RequestLoggers reqLogger) {
		// hardcode BedSheet default middleware
		middleware := Middleware?[
			// FIXME: merge these into ONE to reduce stacktrace
			scope.build(CleanupMiddleware#),
			// loggers wrap ErrMiddleware so they can report 500 errors
			reqLogger,
			scope.build(ErrMiddleware#),
			scope.build(FlashMiddleware#)
		].addAll(userMiddleware).add(scope.build(MiddlewareTerminator#))
		return scope.build(MiddlewarePipelineImpl#, [middleware])
	}

	@Build { scopes=["root"] }
	static HttpRequest buildHttpRequest(DelegateChainBuilder[] builders, Scope reg) {
		httpReq := reg.build(HttpRequestImpl#)
		return builders.isEmpty ? httpReq : makeDelegateChain(builders, httpReq)
	}

	@Build { scopes=["root"] }
	static HttpResponse buildHttpResponse(DelegateChainBuilder[] builders, Scope reg) {
		httpRes := reg.build(HttpResponseImpl#)
		return builders.isEmpty ? httpRes : makeDelegateChain(builders, httpRes)
	}
 
	@Build { serviceId="afBedSheet::HttpOutStream"; scopes=["request"] }
	static OutStream buildHttpOutStream(DelegateChainBuilder[] builders, Scope reg) {
		// FIXME: don't build OutStream builders every request
		makeDelegateChain(builders, reg.build(WebResOutProxy#))
	}

	@Build { scopes=["request"] }	
	private static WebReq buildWebReq() {
		try return Actor.locals["web.req"]
		catch (NullErr e) 
			throw Err("No web request active in thread")
	}

	@Build { scopes=["request"] } 
	private static WebRes buildWebRes() {
		try return Actor.locals["web.res"]
		catch (NullErr e)
			throw Err("No web request active in thread")
	}

	@Contribute { serviceType=DependencyProviders# }
	static Void contributeDependencyProviders(Configuration config) {
		config["afBedSheet.localProvider"] = config.build(LocalProvider#)
	}

	@Contribute { serviceType=ActorPools# }
	static Void contributeActorPools(Configuration config) {
		config["afBedSheet.system"] = ActorPool() { it.name = "afBedSheet.system" }
	}

	@Contribute { serviceType=MiddlewarePipeline# }
	static Void contributeMiddlewarePipeline(Configuration config) {
		config["afBedSheet.assets"] = config.build(AssetsMiddleware#)
		config["afBedSheet.routes"] = config.build(RoutesMiddleware#)
	}

	@Contribute { serviceType=RequestLoggers# }
	static Void contributeRequestLoggers(Configuration config) {
		config["afBedSheet.requestLogger"] = config.build(BasicRequestLogger#)
	}

	@Contribute { serviceType=ClientAssetProducers# }
	static Void contributeAssetProducers(Configuration config, FileHandler fileHandler, PodHandler podHandler) {
		config["afBedSheet.fileHandler"] = fileHandler
		config["afBedSheet.podHandler"]  = podHandler
	}
	
	@Contribute { serviceId="afBedSheet::HttpOutStream" }
	static Void contributeHttpOutStream(Configuration config) {
		config["afBedSheet.safeBuilder"] = HttpOutStreamSafeBuilder()				// inner
		config["afBedSheet.buffBuilder"] = config.build(HttpOutStreamBuffBuilder#)	// middle - buff wraps safe
		config["afBedSheet.gzipBuilder"] = config.build(HttpOutStreamGzipBuilder#)	// outer  - gzip wraps buff
	}

	@Contribute { serviceType=ResponseProcessors# }
	static Void contributeResponseProcessors(Configuration config) {
		config[Asset#]		= config.build(AssetProcessor#)
		config[Err#]		= config.build(ErrProcessor#)
		config[Field#]		= config.build(FieldProcessor#)
		config[File#]		= config.build(FileProcessor#)
		config[Func#]		= config.build(FuncProcessor#)
		config[HttpStatus#]	= config.build(HttpStatusProcessor#)
		config[InStream#]	= config.build(InStreamProcessor#)
		config[MethodCall#]	= config.build(MethodCallProcessor#)
		config[Redirect#]	= config.build(RedirectProcessor#)
		config[Text#]		= config.build(TextProcessor#)
	}

	@Contribute { serviceType=ValueEncoders# }
	static Void contributeValueEncoders(Configuration config) {
		// wot no value encoders!? Aha! I see you're using TypeCoercer as a backup!
	}

	@Contribute { serviceType=PodHandler# }
	static Void contributePodHandlerWhitelist(Configuration config) {
		// by default, allow safe pod files to be served

		// html files
		config[".css"]	= "^.*\\.css\$"
		config[".htm"]	= "^.*\\.htm\$"
		config[".html"]	= "^.*\\.html\$"
		config[".js"]	= "^.*\\.js\$"
		config[".xhtml"]= "^.*\\.xhtml\$"
		
		// image files
		config[".bmp"]	= "^.*\\.bmp\$"
		config[".gif"]	= "^.*\\.gif\$"
		config[".ico"]	= "^.*\\.ico\$"
		config[".jpg"]	= "^.*\\.jpg\$"
		config[".png"]	= "^.*\\.png\$"
		config[".svg"]	= "^.*\\.svg\$"
		
		// web font files
		config[".eot"]	= "^.*\\.eot\$"
		config[".otf"]	= "^.*\\.otf\$"
		config[".ttf"]	= "^.*\\.ttf\$"
		config[".woff"]	= "^.*\\.woff\$"
		
		// other files
		config[".csv"]	= "^.*\\.csv\$"
		config[".txt"]	= "^.*\\.txt\$"
		config[".xml"]	= "^.*\\.xml\$"
	}

	@Contribute { serviceType=GzipCompressible# }
	static Void contributeGzipCompressible(Configuration config) {
		// add some standard compressible mime types
		config["application/atom+xml"]			= true
		config["application/json"]				= true
		config["application/rss+xml"]			= true
		config["application/xhtml+xml"]			= true
		config["text/css"]						= true
		config["text/csv"]						= true
		config["text/fan"]						= true
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
		printer := (NotFoundPrinterHtmlSections) config.build(NotFoundPrinterHtmlSections#)

		// these are all the sections you see on the 404 page
		config["afBedSheet.routeCode"]	= |WebOutStream out| { printer.printRouteCode		(out) }
		config["afBedSheet.routes"]		= |WebOutStream out| { printer.printBedSheetRoutes	(out) }
	}

	@Contribute { serviceType=ErrPrinterHtml# }
	static Void contributeErrPrinterHtml(Configuration config) {
		printer := (ErrPrinterHtmlSections) config.build(ErrPrinterHtmlSections#)

		// these are all the sections you see on the Err500 page
		config["afBedSheet.causes"]					= |WebOutStream out, Err? err| { printer.printCauses				(out, err) }
		config["afBedSheet.availableValues"]		= |WebOutStream out, Err? err| { printer.printAvailableValues		(out, err) }
		config["afBedSheet.iocOperationTrace"]		= |WebOutStream out, Err? err| { printer.printIocOperationTrace		(out, err) }
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
		printer := (ErrPrinterStrSections) config.build(ErrPrinterStrSections#)
		
		// these are all the sections you see in the Err log
		config["afBedSheet.causes"]				=  |StrBuf out, Err? err| { printer.printCauses				(out, err) }
		config["afBedSheet.availableValues"]	=  |StrBuf out, Err? err| { printer.printAvailableValues	(out, err) }
		config["afBedSheet.iocOperationTrace"]	=  |StrBuf out, Err? err| { printer.printIocOperationTrace	(out, err) }
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
	static Void contributeFactoryDefaults(Configuration config, RegistryMeta meta) {
		// honour the system config from Fantom-1.0.66 
		errTraceMaxDepth := (Int) (Env.cur.config(Env#.pod, "errTraceMaxDepth")?.toInt(10, false) ?: 0)
		bedSheetPort	 := meta[BsConstants.meta_proxyPort] ?: meta[BsConstants.meta_appPort]

		config[BedSheetConfigIds.proxyPingInterval]			= 1sec
		config[BedSheetConfigIds.gzipDisabled]				= false
		config[BedSheetConfigIds.gzipThreshold]				= 376
		config[BedSheetConfigIds.responseBufferThreshold]	= 32 * 1024	// todo: why not kB?
		config[BedSheetConfigIds.noOfStackFrames]			= errTraceMaxDepth.max(100)	// big 'cos we hide a lot
		config[BedSheetConfigIds.srcCodeErrPadding]			= 5
		config[BedSheetConfigIds.disableWelcomePage]		= false
		config[BedSheetConfigIds.host]						= "http://localhost:${bedSheetPort}".toUri		
		config[BedSheetConfigIds.podHandlerBaseUrl]			= `/pods/`
		config[BedSheetConfigIds.fileAssetCacheControl]		= null	// don't assume we know how long to cache for
		
		config[BedSheetConfigIds.defaultErrResponse]		= MethodCall(DefaultErrResponse#process).toImmutableFunc
		config[BedSheetConfigIds.defaultHttpStatusResponse]	= MethodCall(DefaultHttpStatusResponse#process).toImmutableFunc
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
		config.add("^.*::MiddlewarePipelineBridge.service.*\$")
		
		// Java code
		config.add("^fan.sys.Method\\\$MethodFunc\\..*\$")
		config.add("^fan.sys.Method\\..*\$")
		config.add("^fan.sys.FanObj.doTrap.*\$")
		config.add("^fan.sys.FanObj.trap.*\$")
		config.add("^fan.sys.Func\\\$Indirect0.call.*\$")
		config.add("^java.lang.reflect..*\$")
	}
	
	static Void defineRegistryStartupShutdown(RegistryBuilder bob) {
		
		bob.addScope("request", true)
		
		bob.onRegistryStartup |config| {
			configSrc 		:= (ConfigSource) config.scope.serviceById(ConfigSource#.qname)
	
			config["afBedSheet.validateHost"] = |->| {
				host := (Uri) configSrc.get(BedSheetConfigIds.host, Uri#)
				validateHost(host)
			}
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
