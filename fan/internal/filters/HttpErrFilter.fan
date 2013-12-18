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
		try {
			return handler.service
			
		} catch (Err err) {
			try {
				response := errProcessors.processErr(err)				
				responseProcessors.processResponse(response)

			} catch (Err doubleErr) {
				// the backup plan for when the err handler errs!
				log.err("ERR thrown when processing $err.typeof.qname", doubleErr)
				log.err("  - Original Err", err)
				
				if (!httpResponse.isCommitted) {
					errText := bedSheetPage.renderErr(doubleErr, !inProd)
					httpResponse.statusCode = 500
					httpResponse.headers.contentType = errText.mimeType
					httpResponse.out.print(errText.text)
				}
			}
			
			return true
		}
	}
}
