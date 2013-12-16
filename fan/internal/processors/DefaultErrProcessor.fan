using afIoc::Inject
using web::WebRes

** Prints the BedSheet Err Page 
@NoDoc
const mixin DefaultErrProcessor : ErrProcessor { }

internal const class DefaultErrProcessorImpl : DefaultErrProcessor {
	private const static Log log := Utils.getLog(DefaultErrProcessor#)

	@Inject	private const HttpResponse 		response
	@Inject	private const ErrPrinterStr 	errPrinterStr
	@Inject	private const BedSheetPage		bedSheetPage

	new make(|This|in) { in(this) }

	override Obj process(Err err) {
		log.err(errPrinterStr.errToStr(err))

		if (!response.isCommitted)	// a sanity check
			response.statusCode = 500
		
		return bedSheetPage.renderErr(err)
	}
}
