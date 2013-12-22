using afIoc::Inject
using web::WebRes

** (Service) - Sends the status code and msg from `HttpStatusErr` to the client. 
@NoDoc
const mixin DefaultHttpStatusProcessor : HttpStatusProcessor { }

internal const class DefaultHttpStatusProcessorImpl : DefaultHttpStatusProcessor {

	@Config { id="afIocEnv.isProd" }
	@Inject private const Bool				inProd
	@Inject	private const HttpResponse 		response
	@Inject	private const BedSheetPage		bedSheetPage
	
	internal new make(|This|in) { in(this) }

	override Obj process(HttpStatus httpStatus) {
		if (!response.isCommitted)	// a sanity check
			response.statusCode = httpStatus.code

		return bedSheetPage.renderHttpStatus(httpStatus, !inProd)
	}	
}

