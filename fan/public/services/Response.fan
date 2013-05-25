using afIoc::Inject
using afIoc::Registry
using web::WebReq
using web::WebRes
using web::WebOutStream


** Because [WebRes]`web::WebRes` isn't 'const'
** 
** This is proxied and always refers to the current request
const mixin Response {

	** Map of HTTP response headers.  You must set all headers before you access out() for the 
	** first time, which commits the response. Throw an err if response is already committed.
	** 
	** @see `web::WebRes.headers`
	abstract Str:Str headers()
	
	** gzipped
	abstract OutStream out()
}

//@NoDoc
internal const class ResponseImpl : Response {
	
	@Inject
	private const Registry registry

	@Inject
	private const GzipCompressible gzipCompressible
	
	new make(|This|in) { in(this) } 

	override Str:Str headers() {
		webRes.headers
	}
	
	override OutStream out() {
		contentType := webRes.headers["Content-Type"]
		mimeType	:= MimeType(contentType, false)

		if (!gzipCompressible.isCompressible(mimeType))
			return webRes.out
		
		doGzip := webReq.headers["Accept-encoding"]?.split(',', true)?.any { it.equalsIgnoreCase("gzip") } ?: false
		if (doGzip)
			webRes.headers["Content-Encoding"] = "gzip"
		
		return doGzip ? Zip.gzipOutStream(webRes.out) : webRes.out
	}
	
	private WebReq webReq() {
		registry.dependencyByType(WebReq#)
	}
	
	private WebRes webRes() {
		registry.dependencyByType(WebRes#)
	}
}