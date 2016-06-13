using afIoc::Inject
using afIoc::Registry
using web::WebReq
using inet::IpAddr
using inet::SocketOptions
using concurrent

** (Service) - An injectable 'const' version of [WebReq]`web::WebReq`.
** 
** This class will always refer to the current web request.
const mixin HttpRequest {

	** Returns 'true' if an 'XMLHttpRequest', as specified by the 'X-Requested-With' HTTP header.
	abstract Bool isXmlHttpRequest()
	
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

	** The URL relative to `BedSheetWebMod`, includes query string and fragment. 
	** Always starts with a '/'.
	** 
	** Examples:
	**   /a/b/index.html
	**   /a?q=bar
	** 
	** This is equivalent to a *local URL*. 
	** 
	** @see `web::WebReq.modRel`
	abstract Uri url()

	** The absolute request URL including the full authority and the query string.  
	** This method is equivalent to:
	** 
	**   "http://" + headers["Host"] + path + url
	**
	** where 'path' is the request path to the current 'WebMod'.
	** 
	** Examples:
	**   http://www.foo.com/a/b/index.html
	**   http://www.foo.com/a?q=bar
	** 
	** @see `web::WebReq.absUri`
	abstract Uri urlAbs()

	** Map of HTTP request headers. The map is readonly and case insensitive.
	** 
	** @see `web::WebReq.headers`
	** 
	** @see `http://en.wikipedia.org/wiki/List_of_HTTP_header_fields#Requests`
	abstract HttpRequestHeaders headers()
		
	** The accepted locales for this request based on the "Accept-Language" HTTP header. List is 
	** sorted by preference, where 'locales.first' is best, and 'locales.last' is worst. This list 
	** is guaranteed to contain Locale("en").
	** 
	** @see `web::WebReq.locales`
	abstract Locale[] locales()
	
	** 'Stash' allows you to store temporary data on the request, to easily pass it between 
	** services and objects.
	** 
	** It is good for a quick win, but if you find yourself consistently relying on it, consider 
	** making a thread scoped service instead. 
  	abstract Str:Obj? stash()

	** Returns the request body.
  	abstract HttpRequestBody body()
	
	** This method will:
	**   1. check that the content-type is form-data
	**   2. get the boundary string
	**   3. invoke the callback for each part.
	**
	** For each part in the stream this calls the given callback function with the part's form 
	** name, headers, and an input stream used to read the part's body.
	** 
	** @see `web::WebReq.parseMultiPartForm`
	abstract Void parseMultiPartForm(|Str formName, InStream in, Str:Str headers| callback)

	abstract SocketOptions socketOptions()
	
}

** Wraps a given `HttpRequest`, delegating all its methods. 
** You may find it handy to use when contributing to the 'HttpRequest' delegate chain.
@NoDoc
const class HttpRequestWrapper : HttpRequest {
	const 	 HttpRequest req
	new 	 make(HttpRequest req) 			{ this.req = req 		} 
	override Bool isXmlHttpRequest()		{ req.isXmlHttpRequest	}
	override Version httpVersion() 			{ req.httpVersion		}
	override Str httpMethod()				{ req.httpMethod		}
	override IpAddr remoteAddr() 			{ req.remoteAddr		}
	override Int remotePort() 				{ req.remotePort		}
	override Uri url() 						{ req.url				}
	override Uri urlAbs() 					{ req.urlAbs			}
	override HttpRequestHeaders headers()	{ req.headers			}
	override Locale[] locales() 			{ req.locales			}
	override Str:Obj? stash()				{ req.stash				}
	override HttpRequestBody body()			{ req.body				}
	override SocketOptions socketOptions()	{ req.socketOptions		}
	override Void parseMultiPartForm(|Str, InStream, Str:Str| cb)	{ req.parseMultiPartForm(cb) }
}

internal const class HttpRequestImpl : HttpRequest {	
	override const HttpRequestHeaders	headers
	@Inject  const |->RequestState|?	reqState	// nullable for testing
	
	new make(|This|? in := null) { 
		in?.call(this) 
		this.headers = HttpRequestHeaders() |->Str:Str| { webReq.headers }
	}
	override Bool isXmlHttpRequest() {
		headers.get("X-Requested-With")?.equalsIgnoreCase("XMLHttpRequest") ?: false
	}
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
	override Uri url() {
		rel := webReq.modRel
		// see [Inconsistent WebReq::modRel()]`http://fantom.org/sidewalk/topic/2237`
		return rel.isPathAbs ? rel : `/` + rel
	}
	override Uri urlAbs() {
		host := headers.host ?: throw Err("Missing Host header")
		return `http://${host}/` + webReq.uri
	}
	override Locale[] locales() {
		webReq.locales
	}
	override Str:Obj? stash() {
		webReq.stash
	}
	override HttpRequestBody body() {
		reqState().requestBody
	}
	override SocketOptions socketOptions()	{
		webReq.socketOptions
	}
	override Void parseMultiPartForm(|Str, InStream, Str:Str| cb) {
		webReq.parseMultiPartForm(cb)
	}
	private WebReq webReq() {
		// let's simplify and optimise, no point in querying IoC for this.
		try return Actor.locals["web.req"]
		catch (NullErr e) 
			throw Err("No web request active in thread")
	}
}
