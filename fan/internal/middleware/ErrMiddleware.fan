using afIoc
using afIocConfig::Config

** Catches and processes Errs. This usually involves generating and sending a error page to the client. 
internal const class ErrMiddleware : Middleware {
	private const static Log log := Utils.getLog(ErrMiddleware#)

	@Config { id="afIocEnv.isProd" }
	@Inject private const Bool					inProd
	
	@Inject	private const ResponseProcessors	responseProcessors
	@Inject	private const HttpRequest			httpRequest
	@Inject	private const HttpResponse			httpResponse
	@Inject	private const BedSheetPages			bedSheetPages

	new make(|This|in) { in(this) }
	
	override Void service(MiddlewarePipeline pipeline) {
		firstErr := null
		response := null

		// the double try 
		try {
			
			try {
				pipeline.service
				return
				
				// nothing we can do here
			} catch (RegistryShutdownErr err) {
				return

			// handle ReProcessErrs as it may be thrown outside of ResponseProcessor (e.g. in middleware), and people 
			// would still expect it work
			} catch (ReProcessErr reErr) {
				if (!httpResponse.isCommitted)
					httpResponse.reset

				firstErr = reErr
				response = reErr.responseObj
				
			} catch (Err err) {
				if (!httpResponse.isCommitted)
					httpResponse.reset

				firstErr = err
				setStackTraceHeader(err)

				// unwrap looking for a ReProcessErr 'cos some frameworks, like efan, may have wrapped it
				cause := (Err?) err
				while (cause != null && cause isnot ReProcessErr)
					cause = cause.cause			
				
				response = cause is ReProcessErr ? ((ReProcessErr) cause).responseObj : err
			}

			while (!response.typeof.fits(Bool#))
				response = responseProcessors.processResponse(response)
			
		} catch (Err doubleErr) {
			// the backup plan for when the err handler errs!
			log.err("ERR thrown when processing $firstErr.typeof.qname", doubleErr)
			log.err("  - Original Err", firstErr)
			
			if (!httpResponse.isCommitted) {
				errText := bedSheetPages.renderErr(doubleErr, !inProd)
				httpResponse.statusCode = 500
				httpResponse.headers.contentType = errText.contentType
				httpResponse.headers.cacheControl = "private, max-age=0, no-store"
				httpResponse.out.print(errText.text)
			}
		}
	}
	
	private Void setStackTraceHeader(Err err) {
		if (!httpResponse.isCommitted && !inProd) {
			
			// IE doesn't like these headers, so if called by a real browser, water down and sanitise them
			if (httpRequest.headers.userAgent != null && httpRequest.headers.userAgent.size > 20) {
				addHeader("X-afBedSheet-errMsg", 		err.msg.replace("\n", " "))
				addHeader("X-afBedSheet-errType", 		err.typeof.qname)				
			} else {
				addHeader("X-afBedSheet-errMsg", 		err.msg)
				addHeader("X-afBedSheet-errType", 		err.typeof.qname)
				addHeader("X-afBedSheet-errStackTrace",	Utils.traceErr(err))
			}
		}
	}
	
	private Void addHeader(Str name, Str value) {		
		httpResponse.headers[name] = value.trim
	}
}
