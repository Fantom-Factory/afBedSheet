using afIoc::Inject
using web::WebRes

** Sends the status code and msg from `HttpStatusErr` to the client. 
@NoDoc
const mixin HttpStatusPageDefault : HttpStatusProcessor { }

internal const class HttpStatusPageDefaultImpl : HttpStatusPageDefault {

	@Inject private const BedSheetPage 	bedSheetPage
	@Inject	private const HttpResponse 	response

	internal new make(|This|in) { in(this) }

	override Text process(HttpStatus httpStatus) {
		if (!response.isCommitted)	// a sanity check
			response.setStatusCode(httpStatus.code)

		title	:= "${httpStatus.code} - " + WebRes.statusMsg[httpStatus.code]
		content	:= "<p><b>${httpStatus.msg}</b></p>"
		return bedSheetPage.render(title, content)
	}	
}
