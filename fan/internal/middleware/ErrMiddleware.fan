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
	@Inject	private const ErrProcessors			errProcessors
	@Inject	private const HttpResponse			httpResponse
	@Inject	private const BedSheetPages			bedSheetPages

	new make(|This|in) { in(this) }
	
	override Bool service(MiddlewarePipeline pipeline) {
		firstErr := null
		response := null

		// the double try 
		try {
			
			try {
				return pipeline.service
				
			// nothing we can do here
			} catch (IocShutdownErr err) {
				return true

			// handle ReProcessErrs as it may be thrown outside of ResponseProcessor (e.g. in middleware), and people 
			// would still expect it work
			} catch (ReProcessErr reErr) {
				firstErr = reErr
				response = reErr.responseObj
				
			} catch (Err otherErr) {
				firstErr = otherErr
				setStackTraceHeader(otherErr)
				response = errProcessors.processErr(otherErr)									
			}

			while (!response.typeof.fits(Bool#))
				try {
					response = responseProcessors.processResponse(response)
				} catch (ReProcessErr rpe) {
					response = rpe.responseObj
				}	
			
			return response

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
			return true
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
		// TODO: report as Fantom web / wisp issue
		// multiple lines in the header need to be prefixed with whitespace
		value = value.splitLines.join("\n ")
		
		// 4096 limit is imposed by web::WebUtil.token() when reading headers,
		// encountered by the BedSheet Dev Proxy when returning the request back to the browser
		value = value[0..<(4096-2).min(value.size)].trim
		
		httpResponse.headers[name] = value
	}
}
