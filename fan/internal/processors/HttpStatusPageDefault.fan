using afIoc::Inject
using afIoc::Registry
using web::WebOutStream
using web::WebRes

** Sends the status code and msg from `HttpStatusErr` to the client. 
@NoDoc
const mixin HttpStatusPageDefault : HttpStatusProcessor { 
	
	// TODO: afPlastic shouldn't need us to redefine mixin methods
	override abstract Obj process(HttpStatus httpStatus)
}

internal const class HttpStatusPageDefaultImpl : HttpStatusPageDefault {

	@Inject private const BedSheetPage 	bedSheetPage
	@Inject	private const HttpResponse 	response

	internal new make(|This|in) { in(this) }

	override TextResponse process(HttpStatus httpStatus) {
		if (!response.isCommitted)	// a sanity check
			response.setStatusCode(httpStatus.code)

		title	:= "${httpStatus.code} - " + WebRes.statusMsg[httpStatus.code]
		content	:= "<p><b>${httpStatus.msg}</b></p>"
		return bedSheetPage.render(title, content)
	}	
}
