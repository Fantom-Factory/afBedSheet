using afIoc::Inject
using web::WebUtil

** Based on `web::FileWeblet`
internal const class FileResponseProcessor : ResponseProcessor {
	
	@Inject	private const HttpRequest 	req
	@Inject	private const HttpResponse 	res
	@Inject	private const FileMetaCache	fileCache
	
	new make(|This|in) { in(this) }
	
	override Obj process(Obj fileObj) {
		fileMeta := fileCache[fileObj]

		if (!fileMeta.exists)
			throw HttpStatusErr(404, "File not found: $req.modRel")

		// I dunno if this should be a 403 or 404. 
		// 403 gives any would be attacker info about your server.
		if (fileMeta.isDir)	// not allowed, until I implement it! 
			throw HttpStatusErr(403, "Directory listing not allowed: $req.modRel")

		// set identity headers
		res.headers.eTag = fileMeta.etag
		res.headers.lastModified = fileMeta.modified

		// initially set the Content-Length 
		// - GzipOutStream may reset this to zero if it kicks in 
		// - BufferedOutStream may override this if needs be 
		res.headers.contentLength = fileMeta.size

		// check if we can return a 304 Not Modified
		if (notModified(req.headers, fileMeta)) {
			res.statusCode = 304
			return true
		}

		mime := fileMeta.file.mimeType
		if (mime != null) 
			res.headers.contentType = mime

		if (req.httpMethod != "HEAD") {
			if (!fileMeta.file.exists) {
				// file doesn't exist anymore - damn that cache!
				fileCache.remove(fileMeta.file)
				throw HttpStatusErr(404, "File not found: $req.modRel")				
			}
			fileMeta.file.in.pipe(res.out, fileMeta.size, true)
		}

		return true
	}
	
	** Check if the request passed headers indicating it has cached version of the file. Return 
	** 'true' If the file has not been modified.
	** 
	** This method supports ETag "If-None-Match" and "If-Modified-Since" modification time.
	virtual Bool notModified(HttpRequestHeaders headers, FileMeta fileMeta) {
		// check If-Match-None
		matchNone := headers.ifNoneMatch
		if (matchNone != null) {
			if (WebUtil.parseList(matchNone).map { WebUtil.fromQuotedStr(it) }.any { it == fileMeta.etag || it == "*" })
				return true
		}
		
		// check If-Modified-Since
		since := headers.ifModifiedSince
		if (since != null) {
			if (fileMeta.modified <= since)
				return true
		}
	
		// gotta do it the hard way
		return false
	}
}
