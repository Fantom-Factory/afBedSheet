using afIoc::Inject
using afIoc::Registry
using web::WebReq
using web::WebUtil
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
	**   "http://" + host + path + url
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

	** Attempts to determine the original 'host' HTTP request header.
	** 
	** Proxy servers such as httpd or AWS ELB, often replace the originating client's 'host' header with their own.
	** This method attempts to untangle common proxy request headers to reform the original 'host'.
	** 
	** The 'host' can be useful to ensure clients contact the correct (sub) domain, and web apps may redirect them if not. 
	** 
	** The 'host' value is formed by inspecting, in order:
	** 
	**  1. the 'forwarded' HTTP header as per [RFC 7239]`https://tools.ietf.org/html/rfc7239`
	**  1. the 'X-Forwarded-XXXX' de-facto standard headers
	**  1. the 'host' standard headers
	** 
	** Typical responses may be:
	** 
	**   http://fantom-lang.org/
	**   //fantom-lang.org/
	** 
	** Note how the scheme may be missing if it can not be reliably obtained.
	** 
	** Note HTTP 1.0 requests are not required to send a host header, for which this method returns 'null'.
	abstract Uri? host()

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
	**   1. Check that the content-type is form-data
	**   2. Get the boundary string
	**   3. Invoke the callback for each part
	**
	** For each part in the stream this calls the given callback function with the part's 
	** name, headers, and an input stream used to read the part's body.
	** 
	** @see `web::WebReq.parseMultiPartForm`
	abstract Void parseMultiPartForm(|Str partName, InStream in, Str:Str headers| callback)

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
	override Uri? host()					{ req.host				}
	override Locale[] locales() 			{ req.locales			}
	override Str:Obj? stash()				{ req.stash				}
	override HttpRequestBody body()			{ req.body				}
	override SocketOptions socketOptions()	{ req.socketOptions		}
	override Void parseMultiPartForm(|Str, InStream, Str:Str| cb)	{ req.parseMultiPartForm(cb) }
}

internal const class HttpRequestImpl : HttpRequest {	
	override const HttpRequestHeaders	headers
	@Inject  const |->RequestState|?	reqState	// nullable for testing
	@Inject  const |->BedSheetServer|?	bedServer
	static	 const Log					log			:= HttpRequestImpl#.pod.log

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
		// use BedServer's fancy Host processing
		bedServer().toAbsoluteUrl(webReq.uri)
	}
	override Uri? host() {
		hostViaHeaders(headers.val)
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
	static Uri? hostViaHeaders(Str:Str headers) {
		forwarded 	:= headers["Forwarded"]
		try {
			if (forwarded != null) {
				forHost := null as Str
				forProt := null as Str

				splits	:= forwarded.split(';')
				splits.each {
					vals := it.split('=')
					if (vals.first.equalsIgnoreCase("proto"))
						forProt = vals.last.startsWith("\"") ? WebUtil.fromQuotedStr(vals.last) : vals.last
					if (vals.first.equalsIgnoreCase("host"))
						forHost = vals.last.startsWith("\"") ? WebUtil.fromQuotedStr(vals.last) : vals.last
				}
				if (forProt != null && forHost != null)
					return `${forProt}://${forHost}`
				if (forHost != null)
					return `//${forHost}/`
			}
		} catch {
			log.warn("Dodgy 'Forwarded' HTTP header value:  Forwarded = ${forwarded}")
		}
			
		proxyScheme := headers["X-Forwarded-Proto"]
		proxyHost	:= headers["X-Forwarded-Host"]
		proxyPort	:= headers["X-Forwarded-Port"]
		try {
			if (proxyHost != null) {
				if (proxyHost.endsWith(":"))
					proxyHost = proxyHost[0..<-1]
				if (proxyPort != null && !proxyHost.contains(":"))
					proxyHost = "${proxyHost}:${proxyPort}"
				if (proxyScheme != null)
					return `${proxyScheme}://${proxyHost}/`
				else
					return `//${proxyHost}/`
			}
		} catch {
			log.warn("Dodgy 'X-Forwarded-XXXX' HTTP header values:\n  X-Forwarded-Proto= ${proxyScheme}\n  X-Forwarded-Host = ${proxyHost}\n  X-Forwarded-Port = ${proxyPort}")
		}
			
		host := headers["Host"]
		try {
			if (host != null)
				return `//${host}/`
		} catch {
			log.warn("Dodgy 'Host' HTTP header value: Host = ${host}")
		}
		
		return null
	}
}
