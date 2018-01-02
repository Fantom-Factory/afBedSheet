using web::Cookie

** A wrapper for HTTP request headers with accessors for commonly used headings.
** 
** Note that the accessors are *safe* and will return 'null', rather than throw an Err, when they encounter a dodgy header value.
** 
** @see `http://en.wikipedia.org/wiki/List_of_HTTP_header_fields`
class HttpRequestHeaders {
	const static private Log 		log := Utils.getLog(HttpRequestHeaders#)
				 private Str:Str	headers

	** Creates a new instance with the given map.
	new fromMap(Str:Str headers) { this.headers = headers }

	** Content-Types that are acceptable for the response.
	** 
	** Example: 'Accept: audio/*; q=0.2, audio/basic'
	QualityValues? accept {
		get { makeIfNotNull("Accept") { QualityValues(it, true) }}
		private set { }
	}

	** List of acceptable encodings.
	** 
	** Example: 'Accept-Encoding: compress;q=0.5, gzip;q=1.0'
	QualityValues? acceptEncoding {
		get { makeIfNotNull("Accept-Encoding") { QualityValues(it, true) }}
		private set { }
	}

	** List of acceptable human languages for the response.
	** 
	** Example: 'Accept-Language: da, en-gb;q=0.8, en;q=0.7'
	QualityValues? acceptLanguage {
		get { makeIfNotNull("Accept-Language") { QualityValues(it, true) }}
		private set { }
	}

	** Authorization header. For *BASIC* authorisation, the credentials should have been encoded 
	** like this:
	** 
	**   syntax: fantom
	**   creds := "Basic " + "${username}:${password}".toBuf.toBase64 
	** 
	** Example: 'Authorization: Basic QWxhZGRpbjpPcGVuU2VzYW1l'
	Str? authorization {
		get { headers["Authorization"] }
		private set { }
	}

	** The length of the request body in octets (8-bit bytes).
	** 
	** Example: 'Content-Length: 348'
	Int? contentLength {
		get { makeIfNotNull("Content-Length") { Int.fromStr(it) }}
		private set { }
	}

	** The MIME type of the body of the request (used with POST and PUT requests)
	** 
	** Example: 'Content-Type: application/x-www-form-urlencoded'
	MimeType? contentType {
		get { makeIfNotNull("Content-Type") { MimeType(it, true) }}
		private set { }
	}

	** HTTP cookies previously sent by the server with 'Set-Cookie'. 
	** 
	** Example: 'Cookie: Version=1; Skin=new;'
	Cookie[]? cookies {
		get { makeIfNotNull("Cookie") |cookieVal->Obj?| { 
			return cookieVal.split(';').map |cookieStr->Cookie?| {
				// corrupted cookies aren't the end of the world - so lets not treat it so!
				// in fact, they're so common, let's not even log them - just ignore them!
				return Cookie(cookieStr, false)
			}.exclude { it == null }
		}}
		private set { }
	}

	// Set as a Str because URI normalises it to always have a trailing slash when by default, 
	// host doesn't have one
	** The domain name of the server (for virtual hosting), and the TCP port number on which the 
	** server is listening. The port number may be omitted if the port is the standard port for 
	** the service requested.
	** 
	** Example: 'Host: www.alienfactory.co.uk:8069'
	Str? host {
		get { headers["Host"] }
		private set { }
	}

	** Allows a '304 Not Modified' to be returned if content is unchanged.
	** 
	** Example: 'If-Modified-Since: Sat, 29 Oct 1994 19:43:31 GMT'
	DateTime? ifModifiedSince {
		get { makeIfNotNull("If-Modified-Since") { DateTime.fromHttpStr(it, true) } }
		private set { }
	}

	** Allows a '304 Not Modified' to be returned if content is unchanged.
	** 
	** Example: 'If-None-Match: "737060cd8c284d8af7ad3082f209582d"'
	Str? ifNoneMatch {
		get { headers["If-None-Match"] }
		private set { }
	}

	** Initiates a request for cross-origin resource sharing.
	** 
	** Example: 'Origin: http://www.example-social-network.com/'
	Uri? origin {
		get { makeIfNotNull("Origin") { Uri.decode(it, true) } }
		private set { }
	}

	** This is the address of the previous web page from which a link to the currently requested 
	** page was followed. 
	** 
	** Example: 'Referer: http://en.wikipedia.org/wiki/Main_Page'
	Uri? referrer {
		// yeah, I know I've mispelt referrer!
		// see `https://en.wikipedia.org/wiki/HTTP_referrer`
		// decode Referer as per `https://security.stackexchange.com/questions/126248/is-displaying-a-non-encoded-http-referer-header-vulnerable-to-xss#126251`
		get { makeIfNotNull("Referer") { Uri.decode(it, true) } }
		private set { }
	}

	** The user agent string of the user agent.
	** 
	** Example: 'User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:12.0) Gecko/20100101 Firefox/21.0'
	Str? userAgent {
		get { headers["User-Agent"] }
		private set { }
	}

	** Mainly used to identify Ajax requests. 
	** 
	** Example: 'X-Requested-With: XMLHttpRequest'
	Str? xRequestedWith {
		get { headers["X-Requested-With"] }
		private set { }
	}

	** Identifies the originating IP address of a client connecting through an HTTP proxy. 
	** 
	** Example: 'X-Forwarded-For: client, proxy1, proxy2'
	Str[]? xForwardedFor {
		get { headers["X-Forwarded-For"]?.split(',') }
		private set { }
	}

	** Returns the associated HTTP header.
	@Operator
	Str? get(Str name) {
		headers[name]
	}

	** Call the specified function for every key/value in the header map.
	Void each(|Str val, Str key| c) {
		headers.each(c)
	}
	
	** Returns a read only map of the request headers.
	Str:Str val() { headers.ro }
	@NoDoc @Deprecated { msg="Use val() instead" }
	Str:Str map() { val }
	
	** Returns a list of all the response header keys.
	Str[] keys() {
		headers.keys
	}

	@NoDoc
	override Str toStr() {
		headers.toStr
	}
	
	private Obj? makeIfNotNull(Str name, |Str->Obj?| func) {
		val := headers[name]
		if (val == null)
			return val
		try		return func(val)
		catch	log.warn("Could not parse dodgy ${name} HTTP Header: ${val}")
		return	null
	}
}
