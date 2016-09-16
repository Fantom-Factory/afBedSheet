using afIoc::Inject
using afIocConfig::Config
using web::WebRes

internal const class DefaultHttpStatusResponse {
	@Config { id="afIocEnv.isProd" }
	@Inject private const Bool				inProd
	@Inject	private const HttpRequest 		httpReq
	@Inject	private const BedSheetPages		bedSheetPages
			private const MimeType			pageContentType
	
	internal new make(|This|in) {
		in(this)
		pageContentType = bedSheetPages.contentType.noParams		
	}

	Obj process() {
		httpStatus := (HttpStatus) httpReq.stash["afBedSheet.httpStatus"]

		// only return the XHTML / HTML status page if it's actually wanted
		accept := httpReq.headers.accept
		if (accept == null || accept.accepts(pageContentType.toStr))
			return bedSheetPages.renderHttpStatus(httpStatus, !inProd)
		
		// give some token plain text
		if (accept.accepts("text/plain"))
			return Text.fromPlain(httpStatus.toStr)

		return true
	}	
}

