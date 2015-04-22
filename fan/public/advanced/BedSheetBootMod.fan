using afIoc
using afIocEnv
using afConcurrent
using concurrent
using web

** A temporary `web::WebMod` that returns a 'startupMessage' while the real web app is booting up.
@NoDoc 
const class BedSheetBootMod : WebMod {
	private const static Log log := Utils.getLog(BedSheetBootMod#)

	private const AtomicBool	started			:= AtomicBool(false)
	private const AtomicRef		startupErrRef	:= AtomicRef()
	private const IocEnv		iocEnv			:= IocEnv()
	private const LocalRef		webModFuncRef	:= LocalRef("bootMod")
	private const AtomicRef		realWebModRef	:= AtomicRef()

	** The Err (if any) that occurred when the web app was booting up.
	Err? startupErr {
		get 		{ startupErrRef.val }
		private set { startupErrRef.val = it }
	}

	** The real web mod this wraps.
	WebMod? webMod {
		get 		{ realWebModRef.val }
		private set { realWebModRef.val = it }
	}

	** When HTTP requests are received when BedSheet is starting up, then this message is returned to the client with a 500 status code.
	** 
	** Defaults to: 'The website is starting up... Please retry in a moment.'
	** 
	** Change it using a ctor it-block:
	** 
	**   BedSheetBootMod(bob) {
	**       it.startupMessage = "Computer Says No..."
	**   }
	const Str startupMessage	:= "The website is starting up... Please retry in a moment."
	
	** A convenience ctor that starts up BedSheet.
	new makeForBedSheet(BedSheetBuilder bob, |This|? f := null) {
		this.webModFuncRef.val = |->WebMod| {
			appName := bob.options[BsConstants.meta_appName]
			port 	:= bob.options[BsConstants.meta_appPort]
			log.info(BsLogMsgs.bedSheetWebMod_starting(appName, port))
			return BedSheetWebMod(bob.build.startup)
		}
		f?.call(this)
	}

	** Creates the real 'WebMod' from a generic function.
	new make(|->WebMod| webModFunc, |This|? f := null) {
		this.webModFuncRef.val = webModFunc
		f?.call(this)
	}
	
	** Should HTTP requests be queued while BedSheet is starting up? 
	** It is handy in dev, because it prevents you from constantly refreshing your browser!
	** But under heavy load in prod, the requests can quickly build up to 100s; so not such a good idea.
	** 
	** Returns 'false' in prod, 'true' otherwise. 
	virtual Bool queueRequestsOnStartup() {
		!iocEnv.isProd
	}

	@NoDoc
	override Void onService() {
		req.mod = this
		
		// Hey! Why you call us when we're not running, eh!??
		if (!started.val)
			return

		if (queueRequestsOnStartup)
			while (webMod == null && startupErr == null) {
				// 200ms should be un-noticable to humans but a lifetime to a computer!
				Actor.sleep(200ms)
			}
		
		// web reqs still come in while we're processing onStart() so dispatch them quickly
		// We used to sleep / queue them up until ready but then, when processing 100s at once, 
		// it was easy to run into race conditions when lazily creating services.
		if (webMod == null && startupErr == null) {
			res := (WebRes) Actor.locals["web.res"]
			res.sendErr(503, startupMessage)
			return
		}

		// rethrow the startup err if one occurred and let Wisp handle it
		if (startupErr != null)
			throw startupErr
		
		webMod.onService
	}
	
	@NoDoc
	override Void onStart() {
		started.val = true
		try {
			// Go!!!
			webMod := ((|->WebMod|) webModFuncRef.val).call
			webMod.onStart
			
			realWebModRef.val = webMod
			
		} catch (Err err) {
			startupErr = err
			throw err
		}
	}
	
	@NoDoc
	override Void onStop() {
		webMod.onStop
		started.val = false
	}
}
