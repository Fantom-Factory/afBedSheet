using afIoc::Inject
using web::WebUtil

** Based on `web::FileWeblet`
internal const class FileResponseProcessor : ResponseProcessor {
	
	@Inject	private const HttpRequest 	req
	@Inject	private const HttpResponse 	res
	
	new make(|This|in) { in(this) }
	
	override Obj process(Obj fileObj) {
		file := (File) fileObj

		if (!file.exists)
			throw HttpStatusErr(404, "File not found: $req.modRel")

		// I dunno if this should be a 403 or 404. 
		// 403 gives any would be attacker info about your server.
		if (file.isDir)	// not allowed, until I implement it! 
			throw HttpStatusErr(403, "Directory listing not allowed: $req.modRel")

		// set identity headers
		res.headers["ETag"] = etag(file)
		res.headers["Last-Modified"] = modified(file).toHttpStr

		// check if we can return a 304 Not Modified
		if (notModified(req.headers, file)) {
			res.setStatusCode(304)
			return true
		}

		mime := file.mimeType
		if (mime != null) 
			res.headers["Content-Type"] = mime.toStr

		file.in.pipe(res.out, file.size)

		return true
	}
	
	** Get the modified time of the file floored to 1 second which is the most precision that HTTP 
	** can deal with.
	virtual DateTime modified(File file) {
		file.modified.floor(1sec)
	}

	** Compute the ETag for the file being serviced which uniquely identifies the file version. The 
	** default implementation is a hash of the modified time and the file size. The result of this 
	** method must conform to the ETag syntax and be wrapped in quotes.
	virtual Str etag(File file) {
		"\"${file.size.toHex}-${file.modified.ticks.toHex}\""
	}
	
	** Check if the request passed headers indicating it has cached version of the file. Return 
	** 'true' If the file has not been modified.
	** 
	** This method supports ETag "If-None-Match" and "If-Modified-Since" modification time.
	virtual Bool notModified(Str:Str headers, File file) {
		// check If-Match-None
		matchNone := headers["If-None-Match"]
		if (matchNone != null) {
			etag := this.etag(file)
			if ( WebUtil.parseList(matchNone).any |Str s->Bool| {
				return s == etag || s == "*"
			})
				return true
		}
		
		// check If-Modified-Since
		since := headers["If-Modified-Since"]
		if (since != null) {
			sinceTime := DateTime.fromHttpStr(since, false)
			if (modified(file) <= sinceTime)
				return true
		}
	
		// gotta do it the hard way
		return false
	}	
}
