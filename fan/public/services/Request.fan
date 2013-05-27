using afIoc::Inject
using afIoc::Registry
using web::WebReq
using inet::IpAddr

** Because [WebReq]`web::WebReq` isn't 'const'
** 
** This is proxied and always refers to the current request
const mixin Request {

	** The HTTP version of the request.
	** 
	** @see `web::WebReq.version`
	abstract Version httpVersion()
	
	** The HTTP request method in uppercase. Example: GET, POST, PUT.
	** 
	** @see `web::WebReq.method`
	abstract Str httpMethod()

	** The IP host address of the client socket making this request.
	** 
	** @see `web::WebReq.remoteAddr`
	abstract IpAddr remoteAddr()
	
	** The IP port of the client socket making this request.
	** 
	** @see `web::WebReq.remotePort`
	abstract Int remotePort()

	** The request URI including the query string relative to this authority. Also see `absUri`, 
	** `modBase`, `modRel`, `routeBase` and `routeRel`.
	** 
	** @see `web::WebReq.uri`
	abstract Uri uri()

	** The absolute request URI including the full authority and the query string.
	** 
	** @see `web::WebReq.absUri`
	abstract Uri absUri()
	
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
	
	** Map of HTTP request headers. The map is readonly and case insensitive.
	** 
	** @see `web::WebReq.headers`
	abstract Str:Str headers()
	
	** The accepted locales for this request based on the "Accept-Language" HTTP header. List is 
	** sorted by preference, where 'locales.first' is best, and 'locales.last' is worst. This list 
	** is guaranteed to contain Locale("en").
	** 
	** @see `web::WebReq.locales`
	abstract Locale[] locales()
	
	** Get the key/value pairs of the form data.  The request content is read and parsed using 
	** `sys::Uri.decodeQuery`.  
	** 
	** If the request content type is not "application/x-www-form-urlencoded" this method returns 
	** 'null'.
	** 
	** @see `web::WebReq.form`
	abstract [Str:Str]? form()
	
}

internal const class RequestImpl : Request {
	
	@Inject
	private const Registry registry
	
	new make(|This|in) { in(this) } 

	override Version httpVersion() {
		webReq.version		
	}
	
	override Str httpMethod() {
		webReq.method
	}	

	override IpAddr remoteAddr() {
		webReq.remoteAddr		
	}
	
	override Int remotePort() {
		webReq.remotePort		
	}

	override Uri uri() {
		webReq.uri
	}
	
	override Uri absUri() {
		webReq.absUri
	}
	
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
	
	override [Str:Str] headers() {
		webReq.headers
	}
	
	override [Str:Str]? form() {
		webReq.form
	}
	
	override Locale[] locales() {
		webReq.locales		
	}
	
	private WebReq webReq() {
		registry.dependencyByType(WebReq#)
	}

	private RouteMatch routeMatch() {
		webReq.stash["bedSheet.routeMatch"]
	}
}