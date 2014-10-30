using afIoc
using afIocConfig

internal const class DefaultErrResponse {
	@Config { id="afIocEnv.isProd" }
	@Inject private const Bool				inProd
	@Inject	private const Log				log
	@Inject	private const HttpRequest		request
	@Inject	private const ErrPrinterStr 	errPrinterStr
	@Inject	private const BedSheetPages		bedSheetPages

	new make(|This|in) { in(this) }

	Obj process() {
		err := request.stash["afBedSheet.err"]
		
		log.err(errPrinterStr.errToStr(err))
		
		return bedSheetPages.renderErr(err, !inProd)
	}	
}
