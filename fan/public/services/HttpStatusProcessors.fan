using afIoc::Inject
using afIoc::Registry
using web::WebRes

** Holds a collection of `HttpStatusProcessor`s.
const class HttpStatusProcessors : ResponseProcessor {

	@Inject @Config { id="afBedSheet.httpStatus.defaultPage" }
	private const HttpStatusProcessor defaultHttpStatusPage
	
	private const Int:HttpStatusProcessor processors

	internal new make(Int:HttpStatusProcessor processors, |This|in) {
		in(this)
		this.processors = processors.toImmutable
	}

	override Obj process(Obj response) {
		httpStatus := (HttpStatus) response 
		return get(httpStatus.code).process(httpStatus)
	}	
	
	private HttpStatusProcessor get(Int status) {
		processors[status] ?: defaultHttpStatusPage
	}	
}
