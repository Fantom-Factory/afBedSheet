using afIoc::Inject
using web::WebOutStream
using web::WebRes

internal const class HttpStatusPage500 : HttpStatusProcessor {
	private const static Log log := Utils.getLog(HttpStatusPage500#)
	
	@Inject private const MoustacheTemplates 	moustaches
	@Inject	private const HttpRequest  			request
	@Inject	private const HttpResponse 			response
	@Inject	private const ErrPrinter 			errPrinter
	
	internal new make(|This|in) { in(this) }

	override Obj process(HttpStatus httpStatus) {
		if (httpStatus.cause != null)
			log.err(errPrinter.errToStr(httpStatus.cause))

		title			:= "${httpStatus.code} - " + WebRes.statusMsg[httpStatus.code]
		bedSheetCss		:= typeof.pod.file(`/res/web/bedSheet.css`).readAllStr
		alienHeadSvg	:= typeof.pod.file(`/res/web/alienHead.svg`).readAllStr
		bedSheetHtml	:= typeof.pod.file(`/res/web/bedSheet.moustache`)
		// TODO: only print the gubbins in devMode
		content			:= errPrinter.errToHtml(httpStatus)
		version			:= typeof.pod.version.toStr
		html 			:= moustaches.renderFromFile(bedSheetHtml, [
			"title"			: title,
			"bedSheetCss"	: bedSheetCss,
			"alienHeadSvg"	: alienHeadSvg,
			"content"		: content,
			"version"		: version
		])

		if (!response.isCommitted)	// a sanity check
			response.setStatusCode(httpStatus.code)
		
		return TextResponse.fromHtml(html)
	}		
}
