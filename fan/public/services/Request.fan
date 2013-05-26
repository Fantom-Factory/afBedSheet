using afIoc::Inject
using afIoc::Registry
using web::WebReq


** Because [WebReq]`web::WebReq` isn't 'const'
** 
** This is proxied and always refers to the current request
const mixin Request {

	** Base uri of the current WebMod
	** 
	** @see `web::WebReq.modBase`
	abstract Uri modBase()

	** The uri relative to `BedSheetWebMod`
	** 
	** @see `web::WebReq.modRel`
	abstract Uri modRel()

	** The uri matched against the `Route`
	abstract Uri routeBase()

	** The uri relative to the `Route`
	abstract Uri routeRel()
	
	** The HTTP request method in uppercase. Example: GET, POST, PUT.
	abstract Str httpMethod()

	** Get the key/value pairs of the form data.  The request content is read and parsed using 
	** `sys::Uri.decodeQuery`.  
	** 
	** If the request content type is not "application/x-www-form-urlencoded" this method returns 
	** 'null'.
	abstract [Str:Str]? form()
	
}

//@NoDoc
internal const class RequestImpl : Request {
	
	@Inject
	private const Registry registry
	
	new make(|This|in) { in(this) } 

	override Uri modBase() {
		webReq.modBase
	}

	override Uri modRel() {
		webReq.modRel
	}
	
	override Uri routeBase() {
		routeMatch.routeBase
	}
	
	override Uri routeRel() {
		routeMatch.routeRel
	}
	
	override Str httpMethod() {
		webReq.method
	}
	
	override [Str:Str]? form() {
		webReq.form
	}
	
	private WebReq webReq() {
		registry.dependencyByType(WebReq#)
	}

	private RouteMatch routeMatch() {
		webReq.stash["bedSheet.routeMatch"]
	}
}