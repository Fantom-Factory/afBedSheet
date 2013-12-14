using afIoc::Inject
using web::WebRes

internal const class HttpStatusPage500 : HttpStatusProcessor {
	private const static Log log := Utils.getLog(HttpStatusPage500#)
	
	@Inject private const BedSheetPage 		bedSheetPage
	@Inject	private const HttpResponse 		response
	@Inject	private const ErrPrinterHtml 	errPrinterHtml
	@Inject	private const ErrPrinterStr 	errPrinterStr
	
	@Config { id="afIocEnv.isProd" }
	@Inject private const Bool				inProd
	
	internal new make(|This|in) { in(this) }

	override Text process(HttpStatus httpStatus) {
		log.err(errPrinterStr.httpStatusToStr(httpStatus))

		if (!response.isCommitted)	// a sanity check
			response.statusCode = httpStatus.code
		
		// disable the detailed err page report in production mode
		title	:= "${httpStatus.code} - " + WebRes.statusMsg[httpStatus.code]
		content	:= inProd ? "<p><b>Internal Server Error</b></p>" : errPrinterHtml.httpStatusToHtml(httpStatus)
		return bedSheetPage.render(title, content, BedSheetLogo.skull)
	}
}
