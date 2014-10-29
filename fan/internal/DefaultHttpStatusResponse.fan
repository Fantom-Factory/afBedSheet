using afIoc::Inject
using afIocConfig::Config
using web::WebRes

internal const class DefaultHttpStatusResponse {
	@Config { id="afIocEnv.isProd" }
	@Inject private const Bool				inProd
	@Inject	private const HttpRequest 		request
	@Inject	private const HttpResponse 		response
	@Inject	private const BedSheetPages		bedSheetPages
	
	internal new make(|This|in) { in(this) }

	Obj process() {
		httpStatus := (HttpStatus) request.stash["afBedSheet.httpStatus"]

		if (!response.isCommitted)	// a sanity check
			response.statusCode = httpStatus.code

		return bedSheetPages.renderHttpStatus(httpStatus, !inProd)
	}	
}

