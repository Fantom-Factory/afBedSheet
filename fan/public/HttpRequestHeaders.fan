
** A wrapped for http request headers with accessors for some commonly used headings.
** 
** @see `https://en.wikipedia.org/wiki/List_of_HTTP_header_fields`
class HttpRequestHeaders {
	
	private Str:Str headers

	internal new make(Str:Str headers) { this.headers = headers }

	** List of acceptable encodings.
	** 
	** Example: 'Accept-Encoding: compress;q=0.5, gzip;q=1.0'
	QualityValues acceptEncoding {
		get { QualityValues(headers["Accept-Encoding"]) }
		private set { }
	}

	Str? accessControlRequestHeaders {
		get { headers["Access-Control-Request-Headers"] }
		private set { }
	}

	Str? accessControlRequestMethod {
		get { headers["Access-Control-Request-Method"]?.upper }
		private set { }
	}

	** The MIME type of the body of the request (used with POST and PUT requests)
	** 
	** Example: 'Content-Type: application/x-www-form-urlencoded'
	MimeType? contentType {
		get { makeIfNotNull("Content-Type") { MimeType(it, true) }}
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
	
	private Obj? makeIfNotNull(Str name, |Obj->Obj| func) {
		val := headers[name]
		return (val == null) ? null : func(val)
	}

}
