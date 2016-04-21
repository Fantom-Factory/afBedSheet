using afIoc
using afIocConfig

internal const class DefaultErrResponse {
	@Config { id="afIocEnv.isProd" }
	@Inject private const Bool				inProd
	@Inject	private const Log				log
	@Inject	private const HttpRequest		httpReq
	@Inject	private const ErrPrinterStr 	errPrinterStr
	@Inject	private const BedSheetPages		bedSheetPages
			private const MimeType			pageContentType

	new make(|This|in) {
		in(this)
		pageContentType = bedSheetPages.contentType.noParams
	}

	Obj process() {
		err := (Err) httpReq.stash[BsConstants.stash_err]

		log.err(errPrinterStr.errToStr(err))

		// only return the XHTML / HTML status page if it's actually wanted
		accept := httpReq.headers.accept
		if (accept == null || accept.accepts(pageContentType.toStr))
			return bedSheetPages.renderErr(err, !inProd)

		// give some token plain text
		if (accept.accepts("text/plain"))
			return Text.fromPlain("500 - ${err.msg}")

		return true
	}	
}
