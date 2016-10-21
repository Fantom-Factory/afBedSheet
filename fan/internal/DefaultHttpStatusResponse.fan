using afIoc::Inject
using afIocConfig::Config
using web::WebRes

internal const class DefaultHttpStatusResponse {
	@Config { id="afIocEnv.isProd" }
	@Inject private const Bool				inProd
	@Inject	private const HttpRequest 		httpReq
	@Inject	private const BedSheetPages		bedSheetPages
	
	internal new make(|This|in) { in(this) }

	Obj process() {
		httpStatus	:= (HttpStatus) httpReq.stash["afBedSheet.httpStatus"]
		page		:= bedSheetPages.renderHttpStatus(httpStatus, !inProd)

		return page ?: true
	}	
}

