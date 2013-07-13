using afIoc::Inject
using afIoc::Registry
using web::WebOutStream
using web::WebRes

** Sends the status code and msg from `HttpStatusErr` to the client. 
internal const class HttpStatusPageDefault : HttpStatusProcessor {

	@Inject private const MoustacheTemplates 	moustaches
	@Inject	private const HttpResponse 			response
	
	internal new make(|This|in) { in(this) }

	override Obj process(HttpStatus httpStatus) {

		title			:= "${httpStatus.code} - " + WebRes.statusMsg[httpStatus.code]
		bedSheetCss		:= typeof.pod.file(`/res/web/bedSheet.css`).readAllStr
		alienHeadSvg	:= typeof.pod.file(`/res/web/alienHead.svg`).readAllStr
		bedSheetHtml	:= typeof.pod.file(`/res/web/bedSheet.moustache`)

		html := moustaches.renderFromFile(bedSheetHtml, [
			"title"			: title,
			"bedSheetCss"	: bedSheetCss,
			"alienHeadSvg"	: alienHeadSvg,
			"content"		: "<p>${httpStatus.msg}</p>"
		])
		
		if (!response.isCommitted)	// a sanity check
			response.setStatusCode(httpStatus.code)
		
		return TextResponse.fromHtml(html)
	}	
}
