using afIoc::Inject
using afIocConfig::Config
using afIocEnv::IocEnv
using web::WebUtil

internal const class FileAssetResponseProcessor : ResponseProcessor {
	
	@Inject	private const HttpRequest 		httpRequest
	@Inject	private const HttpResponse 		httpResponse
	@Inject	private const FileAssetCache 	fileCache
	@Inject	private const IocEnv			iocEnv
	
	@Config { id = "afBedSheet.fileAsset.cacheControl" }
	@Inject	private const Str?			defaultCacheControl
	
	new make(|This|in) { in(this) }
	
	override Obj process(Obj fileAss) {
		fileMeta := (FileAsset) fileAss

		if (!fileMeta.exists)
			throw HttpStatusErr(404, "File not found: $httpRequest.url")

		// I dunno if this should be a 403 or 404. 
		// 403 gives any would be attacker info about your server.
		if (fileMeta.file.isDir)	// not allowed, until I implement it! 
			throw HttpStatusErr(403, "Directory listing not allowed: $httpRequest.url")

		// set cache headers
		if (httpResponse.headers.cacheControl == null && defaultCacheControl != null && iocEnv.isProd)
			httpResponse.headers.cacheControl = defaultCacheControl
		
		// set identity headers
		httpResponse.headers.eTag = fileMeta.etag
		httpResponse.headers.lastModified = fileMeta.modified

		// initially set the Content-Length 
		// - GzipOutStream may reset this to zero if it kicks in 
		// - BufferedOutStream may override this if needs be 
		httpResponse.headers.contentLength = fileMeta.size

		// check if we can return a 304 Not Modified
		if (notModified(httpRequest.headers, fileMeta)) {
			httpResponse.statusCode = 304
			return true
		}

		mime := fileMeta.file.mimeType
		if (mime != null) 
			httpResponse.headers.contentType = mime

		if (httpRequest.httpMethod != "HEAD") {
			if (!fileMeta.file.exists) {
				// file doesn't exist anymore - damn that cache!
				fileCache.remove(fileMeta)
				throw HttpStatusErr(404, "File not found: $httpRequest.url")				
			}
			fileMeta.file.in.pipe(httpResponse.out, fileMeta.size, true)
		}

		return true
	}
	
	** Check if the request passed headers indicating it has cached version of the file. Return 
	** 'true' If the file has not been modified.
	** 
	** This method supports ETag "If-None-Match" and "If-Modified-Since" modification time.
	virtual Bool notModified(HttpRequestHeaders headers, FileAsset fileAsset) {
		// check If-Match-None
		matchNone := headers.ifNoneMatch
		if (matchNone != null) {
			if (WebUtil.parseList(matchNone).map { WebUtil.fromQuotedStr(it) }.any { it == fileAsset.etag || it == "*" })
				return true
		}
		
		// check If-Modified-Since
		since := headers.ifModifiedSince
		if (since != null) {
			if (fileAsset.modified <= since)
				return true
		}
	
		// gotta do it the hard way
		return false
	}
}
