using web::WebUtil

** A wrapper for HTTP response headers with accessors for commonly used headings.
** 
** @see `https://en.wikipedia.org/wiki/List_of_HTTP_header_fields`
const class HttpResponseHeaders {
	
	private const static Log	log				:= HttpResponseHeaders#.pod.log
	private const static Int 	maxTokenSize	:= 4096 - 10	// taken from web::WebUtil.maxTokenSize. -10 for good measure!
	private const |->Str:Str|	getHeaders
	private const |->| 			checkUncommitted

	internal new make(|->Str:Str| getHeaders, |->| checkUncommitted) {
		this.getHeaders = getHeaders
		this.checkUncommitted = checkUncommitted
	}
	
	** Tells all caching mechanisms from server to client whether they may cache this object. It is 
	** measured in seconds.
	** 
	**   Cache-Control: max-age=3600
	Str? cacheControl {
		get { get("Cache-Control") }
		set { addOrRemove("Cache-Control", it) }
	}

	** Usually used to direct the client to display a 'save as' dialog.
	** 
	**   Content-Disposition: Attachment; filename=example.html
	** 
	** @see `http://tools.ietf.org/html/rfc6266`
	Str? contentDisposition {
		get { get("Content-Disposition") }
		set { addOrRemove("Content-Disposition", it) }
	}

	** The type of encoding used on the data.
	** 
	**   Content-Encoding: gzip
	Str? contentEncoding {
		get { get("Content-Encoding") }
		set { addOrRemove("Content-Encoding", it) }
	}

	** The length of the response body in octets (8-bit bytes).
	** 
	**   Content-Length: 348
	Int? contentLength {
		get { makeIfNotNull("Content-Length") { Int.fromStr(it) }}
		set { addOrRemove("Content-Length", it?.toStr) }
	}

	** Mitigates XSS attacks by telling browsers to restrict where content can be loaded from.
	** 
	**   Content-Security-Policy: default-src 'self'; font-src 'self' https://fonts.googleapis.com/; object-src 'none'
	[Str:Str]? contentSecurityPolicy {
		get { makeIfNotNull("Content-Security-Policy") {
			it.split(';').reduce(Str:Str[:]{it.ordered=true}) |Str:Str map, Str dir->Obj| {
				echo(dir)
				echo(dir)
				echo(dir)
				echo(dir)
				vals := dir.split(' ')
				map[vals.first] = vals[1..-1].join(" ")
				return map
			} {echo(it)}
		}}
		set { addOrRemove("Content-Security-Policy", it?.join("; ") |v, k| { "${k} ${v}" }) }
	}

	** The MIME type of this content.
	** 
	**   Content-Type: text/html; charset=utf-8
	MimeType? contentType {
		get { makeIfNotNull("Content-Type") { MimeType(it, true) }}
		set { addOrRemove("Content-Type", it?.toStr) }
	}

	** An identifier for a specific version of a resource, often a message digest.
	** 
	**   ETag: "737060cd8c284d8af7ad3082f209582d"
	Str? eTag {
		get { makeIfNotNull("ETag") { WebUtil.fromQuotedStr(it) }}
		set { addOrRemove("ETag", (it==null) ? null : WebUtil.toQuotedStr(it)) }
	}
	
	** Gives the date/time after which the response is considered stale.
	** 
	**   Expires: Thu, 01 Dec 1994 16:00:00 GMT
	DateTime? expires {
		get { makeIfNotNull("Expires") { DateTime.fromHttpStr(it, true)} }
		set { addOrRemove("Expires", it?.toHttpStr) }
	}

	** The last modified date for the requested object, in RFC 2822 format.
	** 
	**   Last-Modified: Tue, 15 Nov 1994 12:45:26 +0000
	DateTime? lastModified {
		get { makeIfNotNull("Last-Modified") { DateTime.fromHttpStr(it, true)} }
		set { addOrRemove("Last-Modified", it?.toHttpStr) }
	}

	** Used in redirection, or when a new resource has been created.
	** 
	**   Location: http://www.w3.org/pub/WWW/People.html
	Uri? location {
		get { makeIfNotNull("Location") { Uri.decode(it, true) } }
		set { addOrRemove("Location", it?.encode) }
	}

	** Implementation-specific headers.
	** 
	**   Pragma: no-cache
	Str? pragma {
		get { get("Pragma") }
		set { addOrRemove("Pragma", it) }
	}

	** Tells browsers to always use HTTPS. 
	** 
	**   Strict-Transport-Security: max-age=63072000; includeSubDomains; preload
	Str? strictTransportSecurity {
		get { get("Strict-Transport-Security") }
		set { addOrRemove("Strict-Transport-Security", it) }		
	}
	
	** Tells browsers how and when to transmit the HTTP 'Referer' (sic) header. 
	** 
	**   Referrer-Policy: same-origin
	Str? referrerPolicy {
		get { get("Referrer-Policy") }
		set { addOrRemove("Referrer-Policy", it) }		
	}
	
	** Tells downstream proxies how to match future request headers to decide whether the cached 
	** response can be used rather than requesting a fresh one from the origin server.
	** 
	**   Vary: Accept-Encoding
	** 
	** @see [Accept-Encoding, It’s Vary important]`http://blog.maxcdn.com/accept-encoding-its-vary-important/`
	Str? vary {
		get { get("Vary") }
		set { addOrRemove("Vary", it) }
	}

	** WWW-Authenticate header to indicate supported authentication mechanisms.
	** 
	**   WWW-Authenticate: SCRAM hash=SHA-256
	Str? wwwAuthenticate {
		get { get("WWW-Authenticate") }
		set { addOrRemove("WWW-Authenticate", it) }
	}
	
	** Tells browsers to trust the 'Content-Type' header. 
	** 
	**   X-Content-Type-Options: nosniff
	Str? xContentTypeOptions {
		get { get("X-Content-Type-Options") }
		set { addOrRemove("X-Content-Type-Options", it) }
	}

	** Clickjacking protection, set to:
	**  - 'deny' - no rendering within a frame, 
	**  - 'sameorigin' - no rendering if origin mismatch
	** 
	**   X-Frame-Options: deny
	Str? xFrameOptions {
		get { get("X-Frame-Options") }
		set { addOrRemove("X-Frame-Options", it) }
	}

	** Cross-site scripting (XSS) filter.
	** 
	**   X-XSS-Protection: 1; mode=block
	Str? xXssProtection {
		get { get("X-XSS-Protection") }
		set { addOrRemove("X-XSS-Protection", it) }
	}

	** Returns the named response header.
	@Operator
	Str? get(Str name) {
		getHeaders()[name]
	}

	** Sets a response head to the given value.
	** 
	** If the given value is 'null' then it is removed.
	@Operator
	Void set(Str name, Str? value) {
		if (value == null) {
			remove(name)
			return
		}
			
		checkUncommitted()

		maxTokenSize := maxTokenSize
		valueSize	 := value.size

		// Wisp appends whitespace for us, we just need to adjust our calculations
		maxTokenSize -= value.numNewlines * 2

		// 4096 limit is imposed by web::WebUtil.token() when reading headers,
		// encountered by the BedSheet Dev Proxy when returning the request back to the browser
		if (value.size > maxTokenSize) {
			log.warn("HTTP Response Header '${name}' is too large at $value.size chars, trimming to ${maxTokenSize}...")
			value = value[0..<maxTokenSize].trimEnd
		}
		
		getHeaders()[name] = value
	}
	
	** Removes a response header.
	Str? remove(Str name) {
		checkUncommitted()
		return getHeaders().remove(name)
	}

	** Returns a read / write map of the response headers.
	**  
	** It is better to use 'set()' / 'remove()' / or one of the setters on this 'HttpResponseHeaders' instance to change response values.
	** This allows us to check if the response has already been committed before updating header values.
	** 
	** Think of this 'map' as a *get-out-jail* card.
	Str:Str map() {
		getHeaders()
	}

	@NoDoc
	override Str toStr() {
		getHeaders().toStr
	}
	
	private Obj? makeIfNotNull(Str name, |Str->Obj| func) {
		val := get(name)
		// no need for a "try / catch return null" here as the response is in the users hand
		// and should all errors should be avoidable 
		return (val == null) ? null : func(val)
	}

	private Void addOrRemove(Str name, Str? value) {
		if (value == null)
			remove(name)
		else
			set(name, value)
	}
}
