using web::WebUtil

** A wrapper for HTTP response headers with accessors for commonly used headings.
** Accessors return 'null' if the header doesn't exist, or isn't encoded properly.
** 
** @see `https://en.wikipedia.org/wiki/List_of_HTTP_header_fields`
class HttpResponseHeaders {
	
	const static private Log		log				:= HttpResponseHeaders#.pod.log
	const static private Int 		maxTokenSize	:= 4096 - 10	// taken from web::WebUtil.maxTokenSize. -10 for good measure!
				 private Str:Str	headers
				 private |->| 		checkUncommitted

	** Creates a new instance with the given map.
	new fromMap(Str:Str headers) {
		this.headers = headers
		this.checkUncommitted = |->| { }
	}
	
	** BedSheet actually uses this ctor!
	internal new make(Str:Str headers, |->| checkUncommitted) {
		this.headers = headers
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
				vals := dir.split(' ')
				map[vals.first] = vals[1..-1].join(" ")
				return map
			}
		}}
		set { addOrRemove("Content-Security-Policy", it?.join("; ") |v, k| { "${k} ${v}" }?.trimToNull) }
	}

	** Similar to `contentSecurityPolicy` only violations aren't blocked, just reported. Useful for development / testing.
	** 
	**   Content-Security-Policy-Report-Only: default-src 'self'; font-src 'self' https://fonts.googleapis.com/; object-src 'none'
	[Str:Str]? contentSecurityPolicyReportOnly {
		get { makeIfNotNull("Content-Security-Policy-Report-Only") {
			it.split(';').reduce(Str:Str[:]{it.ordered=true}) |Str:Str map, Str dir->Obj| {
				vals := dir.split(' ')
				map[vals.first] = vals[1..-1].join(" ")
				return map
			}
		}}
		set { addOrRemove("Content-Security-Policy-Report-Only", it?.join("; ") |v, k| { "${k} ${v}" }?.trimToNull) }
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

	** Tells browsers how and when to transmit the HTTP 'Referer' (sic) header. 
	** 
	**   Referrer-Policy: same-origin
	Str? referrerPolicy {
		get { get("Referrer-Policy") }
		set { addOrRemove("Referrer-Policy", it) }		
	}

	** Tells browsers to always use HTTPS. 
	** 
	**   Strict-Transport-Security: max-age=63072000; includeSubDomains; preload
	Str? strictTransportSecurity {
		get { get("Strict-Transport-Security") }
		set { addOrRemove("Strict-Transport-Security", it) }		
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
		headers[name]
	}

	** Call the specified function for every key/value in the header map.
	Void each(|Str val, Str key| c) {
		headers.each(c)
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
		
		headers[name] = value
	}
	
	** Removes a response header.
	Str? remove(Str name) {
		checkUncommitted()
		return headers.remove(name)
	}

	** Returns a read only map of the response headers.
	**  
	** Use 'set()' / 'remove()' to modify header values.
	** This allows us to check if the response has already been committed.
	Str:Str val() { headers.ro }
	@NoDoc @Deprecated { msg="Use 'val()' instead" }
	Str:Str map() { val }
	
	** Returns a list of all the response header keys.
	Str[] keys() {
		headers.keys
	}
	
	** Clears all header values.
	** Called by BedSheet before processing an error handler, to reset the response. 
	Void clear() {
		checkUncommitted()
		headers.clear
	}

	** Convenience method for adding CSP directive values.
	** 
	**   syntax: fantom 
	**   headers.addCsp("script-src", "'self'")
	** 
	** Note this method does nothing if the 'Content-Security-Policy' header is not set,
	** or if the given directive (or 'default-src' fallback) is blank.
	** This enables libraries to work effortless with [Sleep Safe]`pod:afSleepSafe`.
	Void addCsp(Str directive, Str value) {
		csp := contentSecurityPolicy ?: Str:Str[:]
		_addCsp(csp, directive, value, false)
		contentSecurityPolicy = csp
	}
	
	** Convenience method for adding CSP directive values.
	** 
	**   syntax: fantom 
	**   headers.addCspReportOnly("script-src", "'self'")
	**
	** Note this method does nothing if the 'Content-Security-Policy' header is not set,
	** or if the given directive (or 'default-src' fallback) is blank.
	** This enables libraries to work effortless with [Sleep Safe]`pod:afSleepSafe`.
	Void addCspReportOnly(Str directive, Str value) {
		csp := contentSecurityPolicyReportOnly ?: Str:Str[:]
		_addCsp(csp, directive, value, false)
		contentSecurityPolicyReportOnly = csp
	}
	
	** The directive is optionally normalised whereby unnecessary values are removed.
	** For example:
	**  - all 'http:XXXX' values are removed if 'http:' is present
	**  - all 'sha256-XXXX' values are removed if 'unsafe-inline' is present.
	** 
	private Void _addCsp(Str:Str csp, Str directive, Str value, Bool normalise) {
		src := csp.get(directive, "")
		if (src.size > 0) src += " "
		src += value
		
		// turns out that normalising values isn't much use, as it's really only:
		//  - unsafe-inline replaces shaXXX-* and nonce-*
		//  - XXXX: replaces XXXX:*
		//
		// what would be of more use (for Duvet et al) is a CSP class that tells you
		// if a URL / scheme is allowed. 
//		if (normalise && directive.endsWith("-src") && directive != "default-src") {
//			def := csp.get("default-src", "")
//			src = normaliseCsp(src, def)
//		}
		csp[directive] = src
	}
	
//	private Str normaliseCsp(Str src, Str def) {
//		srcs := src.split(' ').exclude { it.isEmpty }
//		defs := def.split(' ').exclude { it.isEmpty }
//		
//		dirs := srcs.dup
//		if (dirs.isEmpty)
//			dirs = defs
//		
//		if (dirs.contains("'unsafe-inline'"))
//			srcs = srcs.exclude {
//				it.startsWith("sha256-") ||
//				it.startsWith("sha384-") ||
//				it.startsWith("sha512-") ||
//				it.startsWith("nonce-")
//			}
//		
//		dirs.findAll { it.endsWith(":") }.each |dir| {
//			srcs = srcs.exclude {
//				it.startsWith(dir)
//			}
//		}
//		
//		return srcs.join(" ")
//	}
	
	@NoDoc
	override Str toStr() {
		headers.toStr
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
