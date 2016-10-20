using afIoc
using afIocConfig

internal const class DefaultErrResponse {
	@Config { id="afIocEnv.isProd" }
	@Inject private const Bool				inProd
	@Inject	private const Log				log
	@Inject	private const HttpRequest		httpReq
	@Inject	private const ErrPrinterStr 	errPrinterStr
	@Inject	private const BedSheetPages		bedSheetPages

	new make(|This|in) { in(this) }

	Obj process() {
		err := (Err) httpReq.stash[BsConstants.stash_err]

		log.err(errPrinterStr.errToStr(err))

		page := bedSheetPages.renderErr(err, !inProd)
		return page ?: true
	}	
}
