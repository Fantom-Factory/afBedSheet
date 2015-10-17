using afIoc::IocShutdownErr
using afIoc::Inject
using afIoc::Registry
using afIocConfig::Config

** Catches and processes Errs. This usually involves generating and sending a error page to the client. 
internal const class ErrMiddleware : Middleware {
	private const static Log log := Utils.getLog(ErrMiddleware#)

	@Config { id="afIocEnv.isProd" }
	@Inject private const Bool					inProd
	
	@Inject	private const ResponseProcessors	responseProcessors
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
			} catch (IocShutdownErr shutdownErr) {
				return

			// handle ReProcessErrs as it may be thrown outside of ResponseProcessor (e.g. in middleware), and people 
			// would still expect it work
			} catch (ReProcessErr reErr) {
				firstErr = reErr
				response = reErr.responseObj
				
			} catch (Err err) {
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
			addHeader("X-afBedSheet-errMsg", 		err.msg)
			addHeader("X-afBedSheet-errType", 		err.typeof.qname)
			addHeader("X-afBedSheet-errStackTrace",	Utils.traceErr(err, 100))
		}
	}
	
	private Void addHeader(Str name, Str value) {		
		httpResponse.headers[name] = value.trim
	}
}
