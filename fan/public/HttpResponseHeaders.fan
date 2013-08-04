
** A wrapper for HTTP response headers with accessors for some commonly used headings.
** 
** @see `https://en.wikipedia.org/wiki/List_of_HTTP_header_fields`
class HttpResponseHeaders {
	
	private Str:Str headers

	internal new make(Str:Str headers) { this.headers = headers }
	
	** Tells all caching mechanisms from server to client whether they may cache this object. It is 
	** measured in seconds.
	** 
	** Example: 'Cache-Control: max-age=3600'
	Str? cacheControl {
		get { headers["Cache-Control"] }
		set { addOrRemove("Cache-Control", it) }
	}

	** The type of encoding used on the data.
	** 
	** Example: 'Content-Encoding: gzip'
	Str? contentEncoding {
		get { headers["Content-Encoding"] }
		set { addOrRemove("Content-Encoding", it) }
	}

	** Usually used to direct the client to display a 'save as' dialog.
	** 
	** Example: 'Content-Disposition: Attachment; filename=example.html'
	** 
	** @see `http://tools.ietf.org/html/rfc6266`
	Str? contentDisposition {
		get { headers["Content-Disposition"] }
		set { addOrRemove("Content-Disposition", it) }
	}

	** The length of the response body in octets (8-bit bytes).
	** 
	** Example: 'Content-Length: 348'
	Int? contentLength {
		get { makeIfNotNull("Content-Length") { Int.fromStr(it) }}
		set { addOrRemove("Content-Length", it?.toStr) }
	}

	** The MIME type of this content.
	** 
	** Example: 'Content-Type: text/html; charset=utf-8'
	MimeType? contentType {
		get { makeIfNotNull("Content-Type") { MimeType(it, true) }}
		set { addOrRemove("Content-Type", it?.toStr) }
	}

	** An identifier for a specific version of a resource, often a message digest.
	** 
	** Example: 'ETag: "737060cd8c284d8af7ad3082f209582d"'
	// FIXME: use WebUtil.quotedStr
	Str? eTag {
		get { headers["ETag"] }
		set { addOrRemove("ETag", it) }
	}
	
	** Gives the date/time after which the response is considered stale.
	** 
	** Example: 'Expires: Thu, 01 Dec 1994 16:00:00 GMT'
	DateTime? expires {
		get { makeIfNotNull("Expires") { DateTime.fromHttpStr(it, true)} }
		set { addOrRemove("Expires", it?.toHttpStr) }
	}

	** The last modified date for the requested object, in RFC 2822 format.
	** 
	** Example: 'Last-Modified: Tue, 15 Nov 1994 12:45:26 +0000'
	DateTime? lastModified {
		get { makeIfNotNull("Last-Modified") { DateTime.fromHttpStr(it, true)} }
		set { addOrRemove("Last-Modified", it?.toHttpStr) }
	}

	** Used in redirection, or when a new resource has been created.
	** 
	** Example: 'Location: http://www.w3.org/pub/WWW/People.html'
	Uri? location {
		get { makeIfNotNull("Location") { Uri.decode(it, true) } }
		set { addOrRemove("Location", it?.encode) }
	}

	@Operator
	Str? get(Str name) {
		headers[name]
	}

	@Operator
	Void set(Str name, Str value) {
		headers[name] = value
	}
	
	Str? remove(Str name) {
		headers.remove(name)
	}
	
	Str:Str map() {
		headers
	}
	
	private Obj? makeIfNotNull(Str name, |Obj->Obj| func) {
		val := headers[name]
		return (val == null) ? null : func(val)
	}

	private Void addOrRemove(Str name, Str? value) {
		if (value == null)
			headers.remove(name)
		else
			headers[name] = value
	}
}
