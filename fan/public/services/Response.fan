using afIoc::Inject
using afIoc::Registry
using web::Cookie
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
	
	** Get the list of cookies to set via header fields.  Add a Cookie to this list to set a 
	** cookie.  Throw Err if response is already committed.
	**
	** Example:
	**   res.cookies.add(Cookie("foo", "123"))
	**   res.cookies.add(Cookie("persistent", "some val") { maxAge = 3day })
	abstract Cookie[] cookies()

	** Return true if this response has been commmited.  A committed response has written its 
	** response headers, and can no longer modify its status code or headers.  A response is 
	** committed the first time that `out` is called.
	abstract Bool isCommitted()
	
	** gzipped
	abstract OutStream out()
}

internal const class ResponseImpl : Response {

	@Inject
	private const Registry registry

	@Inject
	private const GzipCompressible gzipCompressible

	new make(|This|in) { in(this) } 

	override Str:Str headers() {
		webRes.headers
	}

	override Cookie[] cookies() {
		webRes.cookies
	}
	
	override Bool isCommitted() {
		webRes.isCommitted
	}

	override OutStream out() {
		contentType := webRes.headers["Content-Type"]
		mimeType	:= MimeType(contentType, false)

		if (!gzipCompressible.isCompressible(mimeType))
			return webRes.out
		
		doGzip := webReq.headers["Accept-encoding"]?.split(',', true)?.any { it.equalsIgnoreCase("gzip") } ?: false
		
		return doGzip ? registry.autobuild(GzipOutStream#) : webRes.out
	}

	private WebReq webReq() {
		registry.dependencyByType(WebReq#)
	}
	
	private WebRes webRes() {
		registry.dependencyByType(WebRes#)
	}
}