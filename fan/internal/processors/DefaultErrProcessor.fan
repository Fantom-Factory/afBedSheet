using afIoc::Inject
using afIocConfig::Config
using web::WebRes

** Prints the BedSheet Err Page 
@NoDoc
const mixin DefaultErrProcessor : ErrProcessor { }

internal const class DefaultErrProcessorImpl : DefaultErrProcessor {
	private const static Log log := Utils.getLog(DefaultErrProcessor#)

	@Config { id="afIocEnv.isProd" }
	@Inject private const Bool				inProd
	
	@Inject	private const HttpResponse 		response
	@Inject	private const ErrPrinterStr 	errPrinterStr
	@Inject	private const BedSheetPages		bedSheetPages

	new make(|This|in) { in(this) }

	override Obj process(Err err) {
		log.err(errPrinterStr.errToStr(err))

		if (!response.isCommitted)	// a sanity check
			response.statusCode = 500
		
		response.headers.cacheControl = "private, max-age=0, no-store"
		
		return bedSheetPages.renderErr(err, !inProd)
	}
}
