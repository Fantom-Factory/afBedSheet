using afIoc::Inject
using afIoc::Registry
using web::WebRes

** Sends the status code and msg in `HttpStatusErr` to the client. 
internal const class HttpStatusErrHandler : ErrHandler {

	@Inject
	private const Registry registry
	
	new make(|This|in) { in(this) }
	
	override Void handle(Err e) {
		HttpStatusErr err := (HttpStatusErr) e
		
		// TODO: have status code handlers
		
		res := (WebRes) registry.dependencyByType(WebRes#)
		res.sendErr(err.statusCode, err.msg)
	}
	
}
