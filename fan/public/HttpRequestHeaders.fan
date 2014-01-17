using web::Cookie

** A wrapper for HTTP request headers with accessors for some commonly used headings.
** 
** @see `http://en.wikipedia.org/wiki/List_of_HTTP_header_fields`
class HttpRequestHeaders {
	
	private Str:Str headers

	internal new make(Str:Str headers) { this.headers = headers }

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

	** List of acceptable human languages for response.
	** 
	** Example: 'Accept-Language: da, en-gb;q=0.8, en;q=0.7'
	QualityValues? acceptLanguage {
		get { makeIfNotNull("Accept-Language") { QualityValues(it, true) }}
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
	Cookie[]? cookie {
		get { makeIfNotNull("Cookie") { it.split(';').map { Cookie.fromStr(it) }}}
		private set { }
	}

	** The domain name of the server (for virtual hosting), and the TCP port number on which the 
	** server is listening. The port number may be omitted if the port is the standard port for 
	** the service requested.
	** 
	** Example: 'Host: www.alienfactory.co.uk:8069'
	Uri? host {
		get { headers["Host"]?.toUri }
		private set { }
	}

	** Allows a 304 Not Modified to be returned if content is unchanged.
	** 
	** Example: 'If-Modified-Since: Sat, 29 Oct 1994 19:43:31 GMT'
	DateTime? ifModifiedSince {
		get { makeIfNotNull("If-Modified-Since") { DateTime.fromHttpStr(it, true) }}
		private set { }
	}

	** Allows a 304 Not Modified to be returned if content is unchanged.
	** 
	** Example: 'If-None-Match: "737060cd8c284d8af7ad3082f209582d"'
	Str? ifNoneMatch {
		get { headers["If-None-Match"] }
		private set { }
	}

	** Initiates a request for cross-origin resource sharing.
	** 
	** Example: 'Origin: http://www.example-social-network.com'
	Str? origin {
		get { headers["Origin"] }
		private set { }
	}

	** This is the address of the previous web page from which a link to the currently requested 
	** page was followed. 
	** 
	** Example: 'Referer: http://en.wikipedia.org/wiki/Main_Page'
	Uri? referrer {
		// yeah, I know I've mispelt referrer!
		// see `https://en.wikipedia.org/wiki/HTTP_referrer`
		get { headers["Referer"]?.toUri }
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

	@Operator
	Str? get(Str name) {
		headers[name]
	}

	Void each(|Str val, Str key| c) {
		headers.each(c)
	}
	
	Str:Str map() {
		headers
	}

	override Str toStr() {
		headers.toStr
	}
	
	private Obj? makeIfNotNull(Str name, |Str->Obj| func) {
		val := headers[name]
		return (val == null) ? null : func(val)
	}
}
