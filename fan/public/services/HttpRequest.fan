using afIoc::Inject
using afIoc::Registry
using web::WebReq
using inet::IpAddr
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
	** Always starts with a '/'. Example, '/index.html'
	** 
	** @see `web::WebReq.modRel`
	abstract Uri url()

	** Map of HTTP request headers. The map is readonly and case insensitive.
	** 
	** @see `web::WebReq.headers`
	** 
	** @see `http://en.wikipedia.org/wiki/List_of_HTTP_header_fields#Requests`
	abstract HttpRequestHeaders headers()
	
	** Get the key/value pairs of the form data.  The request content is read and parsed using 
	** `sys::Uri.decodeQuery`.  
	** 
	** If the request content type is not 'application/x-www-form-urlencoded' this method returns 
	** 'null'.
	** 
	** @see `web::WebReq.form`
	abstract [Str:Str]? form()
	
	** The accepted locales for this request based on the "Accept-Language" HTTP header. List is 
	** sorted by preference, where 'locales.first' is best, and 'locales.last' is worst. This list 
	** is guaranteed to contain Locale("en").
	** 
	** @see `web::WebReq.locales`
	abstract Locale[] locales()
	
	** Get the stream to read request body.  See `web::WebUtil.makeContentInStream` to check under 
	** which conditions request content is available. If request content is not available, then 
	** throw an exception.
	**
	** If the client specified the "Expect: 100-continue" header, then the first access of the 
	** request input stream will automatically send the client a '100 Continue' response.
	**
	** @see `web::WebReq.in`
	abstract InStream in()
	
	** 'Stash' allows you to store temporary data on the request, to easily pass it between 
	** services and objects.
	** 
	** It is good for a quick win, but if you find yourself consistently relying on it, consider 
	** making a thread scoped service instead. 
  	abstract Str:Obj? stash()
	
	** This method will:
	**   1. check that the content-type is form-data
	**   2. get the boundary string
	**   3. invoke the callback for each part (see `WebUtil.parseMultiPart`)
	**
	** For each part in the stream this calls the given callback function with the part's form 
	** name, headers, and an input stream used to read the part's body.
	** 
	** @see `web::WebReq.parseMultiPartForm`
	abstract Void parseMultiPartForm(|Str formName, InStream in, Str:Str headers| callback)

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
	override HttpRequestHeaders headers()	{ req.headers			}
	override [Str:Str]? form() 				{ req.form				}
	override Locale[] locales() 			{ req.locales			}
	override InStream in() 					{ req.in				}	
	override Str:Obj? stash()				{ req.stash				}
	override Void parseMultiPartForm(|Str, InStream, Str:Str| cb)	{ req.parseMultiPartForm(cb) }
}

internal const class HttpRequestImpl : HttpRequest {	
	override const HttpRequestHeaders headers

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
	override [Str:Str]? form() {
		try {
			return webReq.form
		} catch (Err err) {
			throw HttpStatusErr(400, "Invalid Form Data", err)
		}
	}
	override Locale[] locales() {
		webReq.locales
	}
	override InStream in() {
		webReq.in
	}
	override Str:Obj? stash() {
		webReq.stash
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
