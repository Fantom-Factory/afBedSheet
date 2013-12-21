using afIoc::Inject
using afIoc::Registry

** Catches and processes Errs. This usually involves generating and sending a error page to the client. 
internal const class HttpErrFilter : HttpPipelineFilter {
	private const static Log log := Utils.getLog(HttpErrFilter#)

	@Config { id="afIocEnv.isProd" }
	@Inject private const Bool					inProd
	
	@Inject	private const ResponseProcessors	responseProcessors
	@Inject	private const ErrProcessors			errProcessors
	@Inject	private const HttpResponse			httpResponse
	@Inject	private const BedSheetPage			bedSheetPage

	new make(|This|in) { in(this) }
	
	override Bool service(HttpPipeline handler) {
		firstErr := null
		response := null
		
		// the double try 
		try {
			
			try {
				return handler.service
				
			// handle ReProcessErrs as it may be thrown outside of ResponseProcessor (e.g. in a filter), and people 
			// would still expect it work
			} catch (ReProcessErr reErr) {
				firstErr = reErr
				response = reErr.responseObj
				
			} catch (Err otherErr) {
				firstErr = otherErr
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
				errText := bedSheetPage.renderErr(doubleErr, !inProd)
				httpResponse.statusCode = 500
				httpResponse.headers.contentType = errText.mimeType
				httpResponse.out.print(errText.text)
			}
			return true
		}
	}
}
