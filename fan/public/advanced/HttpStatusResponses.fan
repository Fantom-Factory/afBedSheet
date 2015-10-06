using afIoc::Inject
using afIoc::Registry
using afIocConfig::Config
using web::WebRes

** (Service) - Contribute your HttpStatus responses to this.
** 
** @uses a Configuration of 'Int:Obj'
@NoDoc	// Don't overwhelm the masses!
const mixin HttpStatusResponses  {

	abstract Obj lookup(HttpStatus httpStatus)
}

internal const class HttpStatusResponsesImpl : HttpStatusResponses {

	@Inject @Config
	private const Obj		defaultHttpStatusResponse
	private const Int:Obj	responses

	internal new make(Int:Obj responses, |This|in) {
		in(this)
		this.responses = responses.toImmutable
	}

	override Obj lookup(HttpStatus httpStatus) {
		responses[httpStatus.code] ?: defaultHttpStatusResponse
	}	
}
