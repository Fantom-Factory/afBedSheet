using afIoc::Inject
using afIoc::Registry
using afIocConfig::Config
using web::WebRes

** (Service) - Contribute your 'HttpStatusProcessor' implementations to this.
** 
** @uses a MappedConfig of 'Int:HttpStatusProcessor'
@NoDoc	// don't overwhelm the masses!
const mixin HttpStatusProcessors : ResponseProcessor {

	** Returns the result of processing the given `HttpStatus` as per the contributed processors.
	override abstract Obj process(Obj response)
}

internal const class HttpStatusProcessorsImpl : HttpStatusProcessors {

	@Inject @Config { id="afBedSheet.httpStatusProcessors.default" }
	private const HttpStatusProcessor defaultHttpStatusProcessor
	
	private const Int:HttpStatusProcessor processors

	internal new make(Int:HttpStatusProcessor processors, |This|in) {
		in(this)
		this.processors = processors.toImmutable
	}

	** Returns the result of processing the given `HttpStatus` as per the contributed processors.
	override Obj process(Obj response) {
		httpStatus := (HttpStatus) response 
		return get(httpStatus.code).process(httpStatus)
	}	
	
	private HttpStatusProcessor get(Int status) {
		processors[status] ?: defaultHttpStatusProcessor
	}	
}
