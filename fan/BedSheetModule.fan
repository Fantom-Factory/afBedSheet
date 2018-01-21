using web
using afIoc
using afIocEnv
using afIocConfig
using afConcurrent::ActorPools
using afConcurrent::ConcurrentModule
using concurrent::Actor
using concurrent::ActorPool

** The [IoC]`pod:afIoc` module class.
** 
** This class is public so it may be referenced explicitly in test code.
@NoDoc
@SubModule { modules=[IocConfigModule#, BedSheetEnvModule#, ConcurrentModule#] }
const class BedSheetModule {
	// IocConfigModule is referenced explicitly so there is no dicking about with transitive 
	// dependencies on BedSheet startup
	
	Void defineModule(RegistryBuilder defs) {
		defs.addScope("request", true)		

		// Route handlers
		defs.addService(FileHandler#)			.withRootScope
		defs.addService(PodHandler#)			.withRootScope

		// Collections (services with contributions)
		defs.addService(ResponseProcessors#)	.withRootScope
		defs.addService(ErrResponses#)			.withRootScope
		defs.addService(HttpStatusResponses#)	.withRootScope
		defs.addService(Routes#)				.withRootScope
		defs.addService(ValueEncoders#)			.withRootScope

		// Public services - root
		defs.addService(BedSheetServer#)		.withRootScope
		defs.addService(GzipCompressible#)		.withRootScope
		defs.addService(BedSheetPages#)			.withRootScope

		// Public services - request
		defs.addService(RequestLoggers#)		.withRootScope
		defs.addService(HttpSession#)			.withRootScope
		defs.addService(HttpCookies#)			.withRootScope
		defs.addService(HttpRequest#)			.withRootScope
		defs.addService(HttpResponse#)			.withRootScope
		defs.addService(HttpOutStreamWrapper#)	.withRootScope
		defs.addService(HttpOutStream#)			.withScope("request")
		defs.addService(RequestState#)			.withScope("request")

		// Other services - root
		defs.addService(StackFrameFilter#)		.withRootScope
		
		// Other services - request
		defs.addService(NotFoundPrinterHtml#)	.withRootScope
		defs.addService(ErrPrinterHtml#)		.withRootScope
		defs.addService(ErrPrinterStr#)			.withRootScope
		defs.addService(ClientAssetProducers#)	.withRootScope
		defs.addService(ClientAssetCache#)		.withRootScope
		defs.addService(ObjCache#)				.withRootScope

		defs.decorateService(HttpOutStream#.qname) |Configuration config| {
			wraper := (HttpOutStreamWrapper) config.scope.serviceById(HttpOutStreamWrapper#.qname)
			config["afBedSheet.safe"	 ] = |out->OutStream| { wraper.safeWrapper		(out) }	// inner
			config["afBedSheet.buffered" ] = |out->OutStream| { wraper.bufferedWrapper	(out) }	// middle - buff wraps safe
			config["afBedSheet.gzip"	 ] = |out->OutStream| { wraper.gzipWrapper		(out) }	// outer  - gzip wraps buff
			config["afBedSheet.onCcommit"] = |out->OutStream| { wraper.onCommitWrapper	(out) }	// space  - comm wraps gzip
		}
	}

	Void onRegistryStartup(Configuration config, ConfigSource configSrc) {
		config["afBedSheet.validateHost"] = |->| {
			host := (Uri) configSrc.get(BedSheetConfigIds.host, Uri#)
			validateHost(host)
		}
	}

	@Build { scopes=["root"] }
	MiddlewarePipeline buildMiddlewarePipeline(Middleware[] userMiddleware, Scope scope, RequestLoggers reqLogger) {
		// hardcode BedSheet default middleware
		middleware := Middleware?[
			// loggers wrap SystemMiddleware so they can report 500 errors
			reqLogger,
			scope.build(ErrMiddleware#),
		].addAll(userMiddleware).add(scope.build(MiddlewareTerminator#))
		return scope.build(MiddlewarePipelineImpl#, [middleware])
	}

	@Build { scopes=["request"] }	
	WebReq buildWebReq() {
		try return Actor.locals["web.req"]
		catch (NullErr e) 
			throw Err("No web request active in thread")
	}

	@Build { scopes=["request"] } 
	WebRes buildWebRes() {
		try return Actor.locals["web.res"]
		catch (NullErr e)
			throw Err("No web request active in thread")
	}

	@Contribute { serviceType=ActorPools# }
	Void contributeActorPools(Configuration config) {
		// used by ClientAssetCache only
		config["afBedSheet.system"] = ActorPool() { it.name = "afBedSheet.system" }
	}

	@Contribute { serviceType=MiddlewarePipeline# }
	Void contributeMiddlewarePipeline(Configuration config) {
		config["afBedSheet.assets"] = config.build(AssetsMiddleware#)
		config["afBedSheet.routes"] = config.build(RoutesMiddleware#)
	}

	@Contribute { serviceType=RequestLoggers# }
	Void contributeRequestLoggers(Configuration config, IocEnv iocEnv) {
		config["afBedSheet.requestLogger"] = config.build(BasicRequestLogger#, [120])
	}

	@Contribute { serviceType=ClientAssetProducers# }
	Void contributeAssetProducers(Configuration config, FileHandler fileHandler, PodHandler podHandler) {
		config["afBedSheet.fileHandler"] 	= fileHandler
		config["afBedSheet.podHandler"]  	= podHandler
		config["afBedSheet.srcMapHandler"]  = config.build(SrcMapHandler#)
	}

	@Contribute { serviceType=ResponseProcessors# }
	Void contributeResponseProcessors(Configuration config) {
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
	Void contributeValueEncoders(Configuration config) {
		// wot no value encoders!? Aha! I see you're using TypeCoercer as a backup!
		
		// well, I nabbed this one from afFormBean for checkboxes
		config[Bool#] = BoolEncoder()
	}

	@Contribute { serviceType=PodHandler# }
	Void contributePodHandlerWhitelist(Configuration config) {
		// by default, allow safe pod files to be served

		// html files
		config[".css"]		= "^.*\\.css\$"
		config[".htm"]		= "^.*\\.htm\$"
		config[".html"]		= "^.*\\.html\$"
		config[".js"]		= "^.*\\.js\$"
		config[".js.map"]	= "^.*\\.js\\.map\$"
		config[".xhtml"]	= "^.*\\.xhtml\$"
		
		// image files
		config[".bmp"]		= "^.*\\.bmp\$"
		config[".gif"]		= "^.*\\.gif\$"
		config[".ico"]		= "^.*\\.ico\$"
		config[".jpg"]		= "^.*\\.jpg\$"
		config[".png"]		= "^.*\\.png\$"
		config[".svg"]		= "^.*\\.svg\$"
		
		// sound files
		config[".mp3"]		= "^.*\\.mp3\$"
		config[".ogg"]		= "^.*\\.ogg\$"
		config[".wav"]		= "^.*\\.wav\$"
		config[".opus"]		= "^.*\\.opus\$"
		
		// web font files
		config[".eot"]		= "^.*\\.eot\$"
		config[".otf"]		= "^.*\\.otf\$"
		config[".ttf"]		= "^.*\\.ttf\$"
		config[".woff"]		= "^.*\\.woff\$"
		
		// other files
		config[".csv"]		= "^.*\\.csv\$"
		config[".txt"]		= "^.*\\.txt\$"
		config[".xml"]		= "^.*\\.xml\$"
	}

	@Contribute { serviceType=GzipCompressible# }
	Void contributeGzipCompressible(Configuration config) {
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
	Void contributeNotFoundPrinterHtml(Configuration config) {
		printer := (NotFoundPrinterHtmlSections) config.build(NotFoundPrinterHtmlSections#)

		// these are all the sections you see on the 404 page
		config["afBedSheet.routeCode"]		= |WebOutStream out| { printer.printRouteCode	(out) }
		config["afBedSheet.fileHandlers"]	= |WebOutStream out| { printer.printFileHandlers(out) }
		config["afBedSheet.middleware"]		= |WebOutStream out| { printer.printMiddleware	(out) }
		config["afBedSheet.routes"]			= |WebOutStream out| { printer.printRoutes		(out) }
	}

	@Contribute { serviceType=ErrPrinterHtml# }
	Void contributeErrPrinterHtml(Configuration config) {
		funcArgs := [config.build(ErrPrinterHtmlSections#)]

		// these are all the sections you see on the Err500 page
		// stoopid retype - see http://fantom.org/forum/topic/2483
		config["afBedSheet.causes"]					= ErrPrinterHtmlSections#printCauses				.func.bind(funcArgs).retype(|WebOutStream, Err?|#)
		config["afBedSheet.iocOperationTrace"]		= ErrPrinterHtmlSections#printIocOperationTrace		.func.bind(funcArgs).retype(|WebOutStream, Err?|#)
		config["afBedSheet.availableValues"]		= ErrPrinterHtmlSections#printAvailableValues		.func.bind(funcArgs).retype(|WebOutStream, Err?|#)
		config["afBedSheet.stackTrace"]				= ErrPrinterHtmlSections#printStackTrace			.func.bind(funcArgs).retype(|WebOutStream, Err?|#)
		config["afBedSheet.requestDetails"]			= ErrPrinterHtmlSections#printRequestDetails		.func.bind(funcArgs).retype(|WebOutStream, Err?|#)
		config["afBedSheet.requestHeaders"]			= ErrPrinterHtmlSections#printRequestHeaders		.func.bind(funcArgs).retype(|WebOutStream, Err?|#)
		config["afBedSheet.formParameters"]			= ErrPrinterHtmlSections#printFormParameters		.func.bind(funcArgs).retype(|WebOutStream, Err?|#)
		config["afBedSheet.session"]				= ErrPrinterHtmlSections#printSession				.func.bind(funcArgs).retype(|WebOutStream, Err?|#)
		config["afBedSheet.cookies"]				= ErrPrinterHtmlSections#printCookies				.func.bind(funcArgs).retype(|WebOutStream, Err?|#)
		config["afBedSheet.locales"]				= ErrPrinterHtmlSections#printLocales				.func.bind(funcArgs).retype(|WebOutStream, Err?|#)
		config["afBedSheet.iocConfig"]				= ErrPrinterHtmlSections#printIocConfig				.func.bind(funcArgs).retype(|WebOutStream, Err?|#)
		config["afBedSheet.fileHandlers"]			= ErrPrinterHtmlSections#printFileHandlers			.func.bind(funcArgs).retype(|WebOutStream, Err?|#)
		config["afBedSheet.middleware"]				= ErrPrinterHtmlSections#printMiddleware			.func.bind(funcArgs).retype(|WebOutStream, Err?|#)
		config["afBedSheet.routes"]					= ErrPrinterHtmlSections#printRoutes				.func.bind(funcArgs).retype(|WebOutStream, Err?|#)
		config["afBedSheet.locals"]					= ErrPrinterHtmlSections#printLocals				.func.bind(funcArgs).retype(|WebOutStream, Err?|#)
		config["afBedSheet.actorPools"]				= ErrPrinterHtmlSections#printActorPools			.func.bind(funcArgs).retype(|WebOutStream, Err?|#)
		config["afBedSheet.fantomEnvironment"]		= ErrPrinterHtmlSections#printFantomEnvironment		.func.bind(funcArgs).retype(|WebOutStream, Err?|#)
		config["afBedSheet.fantomIndexedProps"]		= ErrPrinterHtmlSections#printFantomIndexedProps	.func.bind(funcArgs).retype(|WebOutStream, Err?|#)
		config["afBedSheet.fantomPods"]				= ErrPrinterHtmlSections#printFantomPods			.func.bind(funcArgs).retype(|WebOutStream, Err?|#)
		config["afBedSheet.environmentVariables"]	= ErrPrinterHtmlSections#printEnvironmentVariables	.func.bind(funcArgs).retype(|WebOutStream, Err?|#)
		config["afBedSheet.fantomDiagnostics"]		= ErrPrinterHtmlSections#printFantomDiagnostics		.func.bind(funcArgs).retype(|WebOutStream, Err?|#)
	}

	@Contribute { serviceType=ErrPrinterStr# }
	Void contributeErrPrinterStr(Configuration config) {
		funcArgs := [config.build(ErrPrinterStrSections#)]
		
		// these are all the sections you see in the Err log
		// stoopid retype - see http://fantom.org/forum/topic/2483
		config["afBedSheet.causes"]				=  ErrPrinterStrSections#printCauses			.func.bind(funcArgs).retype(|StrBuf, Err?|#)
		config["afBedSheet.iocOperationTrace"]	=  ErrPrinterStrSections#printIocOperationTrace	.func.bind(funcArgs).retype(|StrBuf, Err?|#)
		config["afBedSheet.availableValues"]	=  ErrPrinterStrSections#printAvailableValues	.func.bind(funcArgs).retype(|StrBuf, Err?|#)
		config["afBedSheet.stackTrace"]			=  ErrPrinterStrSections#printStackTrace		.func.bind(funcArgs).retype(|StrBuf, Err?|#)
		config["afBedSheet.requestDetails"]		=  ErrPrinterStrSections#printRequestDetails	.func.bind(funcArgs).retype(|StrBuf, Err?|#)
		config["afBedSheet.requestHeaders"]		=  ErrPrinterStrSections#printRequestHeaders	.func.bind(funcArgs).retype(|StrBuf, Err?|#)
		config["afBedSheet.formParameters"]		=  ErrPrinterStrSections#printFormParameters	.func.bind(funcArgs).retype(|StrBuf, Err?|#)
		config["afBedSheet.session"]			=  ErrPrinterStrSections#printSession			.func.bind(funcArgs).retype(|StrBuf, Err?|#)
		config["afBedSheet.cookies"]			=  ErrPrinterStrSections#printCookies			.func.bind(funcArgs).retype(|StrBuf, Err?|#)
		config["afBedSheet.locales"]			=  ErrPrinterStrSections#printLocales			.func.bind(funcArgs).retype(|StrBuf, Err?|#)
		config["afBedSheet.iocConfig"]			=  ErrPrinterStrSections#printIocConfig			.func.bind(funcArgs).retype(|StrBuf, Err?|#)
		config["afBedSheet.middleware"]			=  ErrPrinterStrSections#printMiddleware		.func.bind(funcArgs).retype(|StrBuf, Err?|#)
		config["afBedSheet.routes"]				=  ErrPrinterStrSections#printRoutes			.func.bind(funcArgs).retype(|StrBuf, Err?|#)
		config["afBedSheet.locals"]				=  ErrPrinterStrSections#printLocals			.func.bind(funcArgs).retype(|StrBuf, Err?|#)
		config["afBedSheet.actorPools"]			=  ErrPrinterStrSections#printActorPools		.func.bind(funcArgs).retype(|StrBuf, Err?|#)
		config["afBedSheet.fantomEnvironment"]	=  ErrPrinterStrSections#printFantomEnvironment	.func.bind(funcArgs).retype(|StrBuf, Err?|#)
	}
	
	@Contribute { serviceType=FactoryDefaults# }
	Void contributeFactoryDefaults(Configuration config, RegistryMeta meta, IocEnv iocEnv) {
		// look for the proxyPort (8069) before the appPort (8070) as generally, that's where we want to point to 
		bedSheetPort := meta[BsConstants.meta_proxyPort] ?: meta[BsConstants.meta_appPort]

		config[BedSheetConfigIds.proxyPingInterval]			= 1sec
		config[BedSheetConfigIds.gzipDisabled]				= false
		config[BedSheetConfigIds.gzipThreshold]				= 376
		config[BedSheetConfigIds.responseBufferThreshold]	= 32 * 1024
		config[BedSheetConfigIds.disableWelcomePage]		= false
		config[BedSheetConfigIds.host]						= "http://localhost:${bedSheetPort ?: 80}".toUri		
		config[BedSheetConfigIds.podHandlerBaseUrl]			= `/pod/`
		config[BedSheetConfigIds.srcMapHandlerBaseUrl]		= iocEnv.isDev ? `/dev/` : null
		config[BedSheetConfigIds.fileAssetCacheControl]		= null	// don't assume we know how long to cache for
		
		config[BedSheetConfigIds.defaultErrResponse]		= MethodCall(DefaultErrResponse#process).toImmutableFunc
		config[BedSheetConfigIds.defaultHttpStatusResponse]	= MethodCall(DefaultHttpStatusResponse#process).toImmutableFunc
	}
	
	@Contribute { serviceType=StackFrameFilter# }
	Void contributeStackFrameFilter(Configuration config) {
		// remove meaningless and boring stack frames
		
		// Core Fantom libs
		config.add("^concurrent::Actor._dispatch.*\$")
		config.add("^concurrent::Actor._send.*\$")
		config.add("^concurrent::Actor._work.*\$")
		config.add("^concurrent::ThreadPool\\\$Worker.run.*\$")
		config.add("^wisp::WispActor.*\$")
		
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

	internal static Void validateHost(Uri host) {
		if (host.scheme == null || host.host == null)
			throw BedSheetErr(BsErrMsgs.startup_hostMustHaveSchemeAndHost(BedSheetConfigIds.host, host))
		if (!host.pathStr.isEmpty && host.pathStr != "/")
			throw BedSheetErr(BsErrMsgs.startup_hostMustNotHavePath(BedSheetConfigIds.host, host))		
	}
}
