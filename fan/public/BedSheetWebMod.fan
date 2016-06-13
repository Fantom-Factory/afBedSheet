using concurrent::Actor
using concurrent::ActorPool
using concurrent::AtomicRef
using concurrent::AtomicBool
using web::WebMod
using web::WebReq
using web::WebRes
using afIoc
using afIocConfig::ConfigSource

** The `web::WebMod` that runs in [Wisp]`pod:wisp`. 
const class BedSheetWebMod : WebMod {
	private const static Log log := Utils.getLog(BedSheetWebMod#)

	** Returns 'proj.name' from the application's pod meta, or the pod name if not defined.
	const Str		appName
	
	** The port number this Bed App will be listening on. 
	const Int 		port

	** The IoC registry.
	const Registry	registry

	private const MiddlewarePipeline pipeline

	** Creates this 'WebMod'. Use a 'BedSheetBuilder' to create the 'Registry' instance - it ensures all the options have been set.
	new make(Registry registry) {
		bedServer 		:= (BedSheetServer) registry.activeScope.serviceById(BedSheetServer#.qname)
		this.registry	= registry		
		this.appName 	= bedServer.appName
		this.port 		= bedServer.port
		// BUGFIX: eager load the middleware pipeline, so we can use the ErrMiddleware
		// otherwise Errs thrown when instantiating middleware end up in limbo
		// Errs from the FileHandler ctor are a prime example
		this.pipeline	= registry.activeScope.serviceById(MiddlewarePipeline#.qname)
	}

	@NoDoc
	override Void onService() {
		req.mod = this

		try {
			registry.activeScope.createChildScope("request") {
				// this is actual call to BedSheet! 
				// the rest of this class is just startup and error handling fluff! 
				pipeline.service
			}

		} catch (RegistryShutdownErr err) {
			// nothing we can do here
			if (!webRes.isCommitted)
				webRes.sendErr(500, "BedSheet shutting down...")
			return

		// theoretically, this should have already been dealt with by our ErrMiddleware...
		// ...but it's handy for BedSheet development!
		} catch (Err err) {
			
			// try to send something to the browser
			errLog := err.traceToStr
			try {
				errPrinter := (ErrPrinterStr) registry.activeScope.serviceById(ErrPrinterStr#.qname)
				errLog = errPrinter.errToStr(err)
			} catch {}

			// log and throw, because we don't trust Wisp to log it
			Env.cur.err.printLine(errLog)					
			
			if (!webRes.isCommitted)
				webRes.sendErr(500, "${err.typeof} - ${err.msg}")

			throw err
		}
	}

	@NoDoc
	override Void onStart() {
		// start the destroyer!
		meta := (RegistryMeta) registry.activeScope.serviceById(RegistryMeta#.qname)
		if (meta.options[BsConstants.meta_pingProxy] == true) {
			pingPort := (Int) meta.options[BsConstants.meta_proxyPort]
			destroyer := (AppDestroyer) registry.activeScope.build(AppDestroyer#, [ActorPool(), pingPort])
			destroyer.start
		}

		// print BedSheet connection details
		configSrc := (ConfigSource) registry.activeScope.serviceByType(ConfigSource#)
		host := (Uri) configSrc.get(BedSheetConfigIds.host, Uri#)			
		log.info(BsLogMsgs.bedSheetWebMod_started(appName, host))
	}
	
	@NoDoc
	override Void onStop() {
		registry.shutdown
		log.info(BsLogMsgs.bedSheetWebMod_stopping(appName))
	}

	
	private static WebRes webRes() {
		try return Actor.locals["web.res"]
		catch (NullErr e) 
			throw Err("No web request active in thread")
	}
}
