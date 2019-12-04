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

	** The url path component, cached.
	abstract Str[] urlPath()

	** Returns the absolute request URL including the full authority, mod path, and the query string.  
	** If defined, this is taken from the `BedSheetConfigIds.host` config value othereise
	** efforts are made to restore the original HTTP header 'host' should it have been lost / replaced by a proxy.
	** 
	** Equivalent(ish) to:
	**   
	**   host() + WebReq.absUri
	** 
	** Examples:
	**   http://www.foo.com/a/b/index.html
	**   http://www.foo.com/a?q=bar
	** 
	** @see `host`
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

internal const class HttpRequestImpl : HttpRequest {	
	static	 const Log					log			:= HttpRequestImpl#.pod.log
	@Inject  const |->RequestState|?	reqState	// nullable for testing
	@Inject  const |->BedSheetServer|?	bedServer	// nullable for testing

	new make(|This|? in := null) { 
		in?.call(this) 
	}
	override HttpRequestHeaders	headers() {
		reqState().requestHeaders
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
		
		// sometimes Wisp passes dodgy URLs like `//dev/` - usually from hack attempts, e.g. //wp-admin/install.php
		// don't bother logging it, just sort it so an appropriate error page can be served (e.g. 404)
		while (rel.toStr.startsWith("//"))
			rel = rel.toStr[1..-1].toUri
		
		// see [Inconsistent WebReq::modRel()]`http://fantom.org/sidewalk/topic/2237`
		return rel.isPathAbs ? rel : `/` + rel
	}
	override Str[] urlPath() {
		if (webReq.stash.containsKey("afBedSheet.urlPath") == false)
			webReq.stash["afBedSheet.urlPath"] = webReq.modRel.path
		return webReq.stash["afBedSheet.urlPath"]
	}
	override Uri urlAbs() {
		host := bedServer().host
		if (host.scheme == null)
			host = `http:${host}`
		return host + webReq.uri
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
		// copied from 'webReq.parseMultiPartForm()' but uses body.in.
		mime := MimeType(this.headers["Content-Type"])
		if (mime.subType != "form-data") throw Err("Invalid content-type: $mime")
		boundary := mime.params["boundary"] ?: throw Err("Missing boundary param: $mime")
		WebUtil.parseMultiPart(body.in, boundary) |partHeaders, partIn| {
			cd			:= partHeaders["Content-Disposition"] ?: throw Err("Multi-part missing Content-Disposition")
			semi		:= cd.index(";") ?: throw Err("Expected semicolon; Content-Disposition: $cd")
			params		:= MimeType.parseParams(cd[cd.index(";")+1..-1])
			formName	:= params["name"] ?: throw Err("Expected name param; Content-Disposition: $cd")
			cb(formName, partIn, partHeaders)
			try { partIn.skip(Int.maxVal) } catch {} // drain stream
		}
	}
	override Str toStr() {
		"$httpMethod $url"
	}
	private WebReq? webReq(Bool checked := true) {
		// let's simplify and optimise, no point in querying IoC for this.
		try return Actor.locals["web.req"]
		catch (NullErr e) 
			if (checked) throw Err("No web request active in thread"); else return null
	}
	static Uri? hostViaHeaders(Str:Str headers) {
		proto	:= null as Str
		host	:= null as Str
		port	:= null as Str
		
		forwarded 	:= headers["Forwarded"]
		try {
			// note rfc7239 doesn't define a port number for the host
			if (forwarded != null) {
				splits	:= forwarded.split(';')
				splits.each {
					vals := it.split('=')
					if (vals.first.equalsIgnoreCase("proto"))
						proto = vals.last.startsWith("\"") ? WebUtil.fromQuotedStr(vals.last) : vals.last
					if (vals.first.equalsIgnoreCase("host"))
						host  = vals.last.startsWith("\"") ? WebUtil.fromQuotedStr(vals.last) : vals.last
				}
			}
		} catch {
			log.warn("Dodgy 'Forwarded' HTTP header value:  Forwarded = ${forwarded}")
		}
		
		if (forwarded == null) {
			proxyProto	:= headers["X-Forwarded-Proto"]
			proxyHost	:= headers["X-Forwarded-Host"]
			proxyPort	:= headers["X-Forwarded-Port"]
			try {
				if (proxyHost != null) {
					if (proxyHost.endsWith(":"))
						proxyHost = proxyHost[0..<-1]
					if (proxyHost.contains(":")) {
						i := proxyHost.index(":")
						if (proxyPort == null)
							proxyPort = proxyHost[i+1..-1]
						proxyHost = proxyHost[0..<i]
					}
				}
				
				proto	= proxyProto
				host	= proxyHost
				port	= proxyPort
			} catch {
				log.warn("Dodgy 'X-Forwarded-XXXX' HTTP header values:\n  X-Forwarded-Proto=${proxyProto}\n  X-Forwarded-Host=${proxyHost}\n  X-Forwarded-Port=${proxyPort}")
			}
		}
		
		if (host == null)
			host = headers["host"]

		try {
			if (host == null)
				return null
			
			if (proto != null && port != null)
				return `${proto}://${host}:${port}/`
				
			if (proto != null)
				return `${proto}://${host}/`

			if (port != null)
				return `//${host}:${port}/`

			return `//${host}/`
		} catch {
			log.warn("Dodgy 'proto' & 'Host' values: proto=${proto}  host=${host}  port=${port}")
		}

		return null
	}
}
