using afIoc::Inject
using web::WebOutStream
using web::WebRes

internal const class HttpStatusPage500 : HttpStatusProcessor {
	private const static Log log := Utils.getLog(HttpStatusPage500#)
	
	@Inject private const BedSheetPage 	bedSheetPage
	@Inject	private const HttpResponse 	response
	@Inject	private const ErrPrinter 	errPrinter
	
	internal new make(|This|in) { in(this) }

	override TextResponse process(HttpStatus httpStatus) {
		if (httpStatus.cause != null)
			log.err(errPrinter.errToStr(httpStatus.cause))

		if (!response.isCommitted)	// a sanity check
			response.setStatusCode(httpStatus.code)
		
		// TODO: only print the Err gubbins in devMode
		title			:= "${httpStatus.code} - " + WebRes.statusMsg[httpStatus.code]
		content			:= errPrinter.errToHtml(httpStatus)
		return bedSheetPage.render(title, content)
	}		
}
