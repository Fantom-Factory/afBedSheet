using concurrent::Actor
using concurrent::ActorPool
using concurrent::AtomicRef
using concurrent::AtomicBool
using web::WebMod
using web::WebReq
using web::WebRes
using afIoc::IocErr
using afIoc::IocShutdownErr
using afIoc::Registry
using afIoc::RegistryMeta
using afIocEnv::IocEnv
using afIocConfig::ConfigSource

** The `web::WebMod` to be passed to [Wisp]`http://fantom.org/doc/wisp/index.html`. 
const class BedSheetWebMod : WebMod {
	private const static Log log := Utils.getLog(BedSheetWebMod#)

	@NoDoc @Deprecated { msg="Use 'appName' instead" }
	const Str 		moduleName
	
	** Returns 'proj.name' from the application's pod meta, or the pod name if not defined.
	const Str		appName
	
	** The port number this Bed App will be listening on. 
	const Int 		port

	** The IoC registry. 
	const Registry registry

	** The Err (if any) that occurred on service startup
	Err? startupErr {
		get { startupErrRef.val }
		private set { startupErrRef.val = it }
	}

	** When HTTP requests are received when BedSheet is starting up, then this message is returned to the client with a 500 status code.
	** 
	** Defaults to: 'The website is starting up... Please retry in a moment.'
	** 
	** Change it using a ctor it-block:
	** 
	**   BedSheetWebMod(reg) {
	**       it.startupMessage = "Computer Says No..."
	**   }
	const Str startupMessage	:= "The website is starting up... Please retry in a moment."

	private const AtomicBool	started			:= AtomicBool(false)
	private const AtomicRef		startupErrRef	:= AtomicRef()
	private const AtomicRef		pipelineRef		:= AtomicRef()
	private const AtomicRef		errPrinterRef	:= AtomicRef()
	private const IocEnv		iocEnv

	** Creates this 'WebMod'. Use 'BedSheetBuilder' to create the 'Registry' instance - it ensures all the options have been set.
	new make(Registry registry, |This|? f := null) {
		meta := (RegistryMeta) registry.serviceById(RegistryMeta#.qname)
		pod  := (Pod?)  meta.options["afBedSheet.appPod"]
		mod  := (Type?) meta.options["afBedSheet.appModule"]
		this.registry	= registry
		this.moduleName = (pod?.name ?: mod?.qname) ?: "UNKNOWN"
		this.appName 	= meta.options["afBedSheet.appName"]
		this.port 		= meta.options["afBedSheet.port"]
		this.iocEnv		= registry.serviceById(IocEnv#.qname)
		f?.call(this)
	}

	@NoDoc
	override Void onService() {
		req.mod = this
		
		// Hey! Why you call us when we're not running, eh!??
		if (!started.val)
			return

		if (queueRequestsOnStartup)
			while (middlewarePipeline == null && startupErr == null) {
				// 200ms should be un-noticable to humans but a lifetime to a computer!
				Actor.sleep(200ms)
			}
		
		// web reqs still come in while we're processing onStart() so dispatch them quickly
		// We used to sleep / queue them up until ready but then, when processing 100s at once, 
		// it was easy to run into race conditions when lazily creating services.
		if (middlewarePipeline == null && startupErr == null) {
			res := (WebRes) Actor.locals["web.res"]
			res.sendErr(503, startupMessage)
			return
		}

		// rethrow the startup err if one occurred and let Wisp handle it
		if (startupErr != null)
			throw startupErr
		
		try {
			middlewarePipeline.service
			
		} catch (IocShutdownErr err) {
			// nothing we can do here
			return

		// theoretically, this should have already been dealt with by our ErrMiddleware...
		// ...but it's handy for BedSheet development!
		} catch (Err err) {
			
			// try to send something to the browser
			errLog := err.traceToStr
			try {
				errPrinter := (ErrPrinterStr) registry.serviceById(ErrPrinterStr#.qname)
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
		started.val = true
		try {
			log.info(BsLogMsgs.bedSheetWebMod_starting(appName, port))

			// Go!!!
			registry.startup

			// start the destroyer!
			meta := (RegistryMeta) registry.serviceById(RegistryMeta#.qname)
			if (meta.options["afBedSheet.pingProxy"] == true) {
				pingPort := (Int) meta.options["afBedSheet.proxyPort"]
				destroyer := (AppDestroyer) registry.autobuild(AppDestroyer#, [ActorPool(), pingPort])
				destroyer.start
			}

			// print BedSheet connection details
			configSrc := (ConfigSource) registry.dependencyByType(ConfigSource#)
			host := (Uri) configSrc.get(BedSheetConfigIds.host, Uri#)			
			log.info(BsLogMsgs.bedSheetWebMod_started(meta.options["afBedSheet.appName"], host))

			// BUGFIX: eager load the middleware pipeline, so we can use the ErrMiddleware
			// otherwise Errs thrown when instantiating middleware end up in limbo
			// Errs from the FileHandler ctor are a prime example
			pipelineRef.val = registry.serviceById(MiddlewarePipeline#.qname)
			
		} catch (Err err) {
			startupErr = err
			throw err
		}
	}
	
	@NoDoc
	override Void onStop() {
		registry.shutdown
		log.info(BsLogMsgs.bedSheetWebMod_stopping(appName))
	}

	** Should HTTP requests be queued while BedSheet is starting up? 
	** It is handy in dev, because it prevents you from constantly refreshing your browser!
	** But under heavy load in prod, the requests can quickly build up to 100s; so not such a good idea.
	** 
	** Returns 'false' in prod, 'true' otherwise. 
	virtual Bool queueRequestsOnStartup() {
		!iocEnv.isProd
	}
	
	private MiddlewarePipeline? middlewarePipeline() {
		pipelineRef.val
	}
	
	private static WebRes webRes() {
		try return Actor.locals["web.res"]
		catch (NullErr e) 
			throw Err("No web request active in thread")
	}
}
