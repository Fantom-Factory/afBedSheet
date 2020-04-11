using concurrent::ActorPool
using concurrent::AtomicRef
using web::WebMod
using web::WebClient
using afIoc::Registry
using afIoc::RegistryMeta
using afIoc::RegistryShutdownErr
using afIocConfig::ConfigSource

** The `web::WebMod` that runs in [Wisp]`pod:wisp`. 
const class BedSheetWebMod : WebMod {
	private const static Log log := Utils.log

	** Returns 'pod.dis' (or 'proj.name'if not found) from the application's pod meta, or the pod name if neither are defined.
	const Str		appName
	
	** The port number this Bed App will be listening on. 
	const Int 		port

	** The IoC registry.
	const Registry	registry

	private const MiddlewarePipeline	pipeline
	private const AtomicRef				podCheckerRef	:= AtomicRef(null)

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

		if (podCheckerRef.val != null) {
			if (req.modRel == BsConstants.pingUrl) {
				// web pages ping us to check if we've restarted yet
				res.headers["Content-Type"] = MimeType("text/plain").toStr
				res.out.print("OK").flush.close
				return
			}
		
			if (appRequiresRestart) {
				notifyClientOfRestart
				restartApp
				return
			}
		}

		try {
			registry.activeScope.createChild("httpRequest") {
				// this is the actual call to BedSheet! 
				// the rest of this class is just startup and error handling fluff! 
				pipeline.service
			}

		} catch (RegistryShutdownErr err) {
			// nothing we can do here
			if (!res.isCommitted)
				res.sendErr(500, "BedSheet shutting down...")
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
			
			if (!res.isCommitted)
				res.sendErr(500, "${err.typeof} - ${err.msg}")

			throw err
		}
	}

	@NoDoc
	override Void onStart() {
		// start the destroyer!
		meta := (RegistryMeta)   registry.activeScope.serviceById(RegistryMeta#.qname)
		beds := (BedSheetServer) registry.activeScope.serviceById(BedSheetServer#.qname)

		if (meta.options[BsConstants.meta_watchdog] == true) {
			pingPort := (Int) meta.options[BsConstants.meta_watchdogPort]
			destroyer := (AppDestroyer) registry.activeScope.build(AppDestroyer#, [ActorPool(), pingPort])
			destroyer.start
			
			watchAllPods := meta.options[BsConstants.meta_watchAllPods]?.toStr?.toBool(false) ?: false
			appPod		 := (Pod) meta.options[BsConstants.meta_appPod]
			if (appPod.meta["pod.isScript"] == "true")
				throw Err(BsLogMsgs.appRestarter_canNotProxyScripts(appPod.name))
			podChecker := PodChecker(appPod.name, watchAllPods)
			this.podCheckerRef.val = podChecker.initialise
		}

		// print BedSheet connection details
		configSrc := (ConfigSource) registry.activeScope.serviceByType(ConfigSource#)
		host := (Uri) configSrc.get(BedSheetConfigIds.host, Uri#)
		ver  := beds.appPod?.version
		log.info(BsLogMsgs.bedSheetWebMod_started(appName, ver, host))
	}
	
	@NoDoc
	override Void onStop() {
		registry.shutdown
		log.info(BsLogMsgs.bedSheetWebMod_stopping(appName))
	}
	
	private Bool appRequiresRestart() {
		((PodChecker?) podCheckerRef.val)?.podsModifed ?: false
	}
	
	private Void notifyClientOfRestart() {
		registry.activeScope.createChild("httpRequest") {
			msg		:= ((PodChecker?) podCheckerRef.val)?.restartMsg ?: "Just because I feel like it."
			meta	:= (RegistryMeta)  it.serviceById(RegistryMeta#.qname)
			pages	:= (BedSheetPages) it.serviceById(BedSheetPages#.qname)
			appPod	:= (Pod) meta.options[BsConstants.meta_appPod]
			text	:= pages.renderRestart(appName, appPod.version, msg)
			buf		:= text.toBuf
			
			res.statusCode					= 503
			res.headers["Content-Type"]		= text.contentType.toStr
			res.headers["Content-Length"]	= buf.size.toStr
			res.out.writeBuf(buf).flush.close
		}
	}
	
	private Void restartApp() {
		meta	:= (RegistryMeta) registry.activeScope.serviceById(RegistryMeta#.qname)
		dogPort	:= (Int) meta.options[BsConstants.meta_watchdogPort]

		try {
			resBody := WebClient() {
				reqUri = "http://localhost:${dogPort}${BsConstants.restartUrl}".toUri
			}.getStr.trim

			if (resBody != "OK")
				throw IOErr("Watchdog not OK: $resBody")

		} catch (Err err) {
			log.warn("Could not restart App: $err.msg")
		}
	}
}
