using afIoc::Inject
using afIocConfig::Config
using afIocEnv::IocEnv
using web::WebUtil

internal const class AssetProcessor : ResponseProcessor {
	
	@Inject	private const HttpRequest 		httpRequest
	@Inject	private const HttpResponse 		httpResponse
	@Inject	private const ClientAssetCache 	assetCache
	@Inject	private const IocEnv			iocEnv
	
	@Config { id = "afBedSheet.fileAsset.cacheControl" }
	@Inject	private const Str?			defaultCacheControl
	
	new make(|This|in) { in(this) }
	
	override Obj process(Obj obj) {
		asset := (Asset) obj

		if (!asset.exists) {
			assetCache.remove((asset as ClientAsset)?.localUrl)
			throw HttpStatusErr(404, "File not found: $httpRequest.url")
		}

		// set cache headers
		if (httpResponse.headers.cacheControl == null && defaultCacheControl != null && iocEnv.isProd)
			httpResponse.headers.cacheControl = defaultCacheControl
		
		// set identity headers
		httpResponse.headers.eTag 		  = asset.etag
		httpResponse.headers.lastModified = asset.modified.floor(1sec)	// 1 second which is the most precision that HTTP can deal with

		// initially set the Content-Length 
		// - GzipOutStream may reset this to zero if it kicks in 
		// - BufferedOutStream may override this if needs be 
		httpResponse.headers.contentLength = asset.size

		// check if we can return a 304 Not Modified
		if (notModified(httpRequest.headers, asset)) {
			httpResponse.statusCode = 304
			return true
		}

		mime := asset.contentType
		if (mime != null) 
			httpResponse.headers.contentType = mime

		if (httpRequest.httpMethod != "HEAD") {
			in := asset.in
			if (in == null) {
				// oh, it really doesn't exist! (damn that caching!)
				assetCache.remove((asset as ClientAsset)?.localUrl)
				throw HttpStatusErr(404, "File not found: $httpRequest.url")
			}
			try	
				in.pipe(httpResponse.out, asset.size, true)
			catch (IOErr ioe) {
				// guard against 'Unexpected end of stream'
				// oh, it really doesn't exist! (damn that caching!)
				assetCache.remove((asset as ClientAsset)?.localUrl)
				throw HttpStatusErr(404, "File not found: $httpRequest.url")				
			}
		}

		return true
	}
	
	** Check if the request passed headers indicating it has cached version of the file. Return 
	** 'true' If the file has not been modified.
	** 
	** This method supports ETag "If-None-Match" and "If-Modified-Since" modification time.
	virtual Bool notModified(HttpRequestHeaders headers, Asset asset) {
		// check If-Match-None
		matchNone := headers.ifNoneMatch
		if (matchNone != null) {
			if (WebUtil.parseList(matchNone).map |str->Str| {
				try   return WebUtil.fromQuotedStr(str)
				catch return str
			}.any { it == asset.etag || it == "*" })
				return true
		}
		
		// check If-Modified-Since
		since := headers.ifModifiedSince
		if (since != null) {
			if (asset.modified.floor(1sec) <= since)
				return true
		}
	
		// gotta do it the hard way
		return false
	}
}
