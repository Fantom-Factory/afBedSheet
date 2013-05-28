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

	** Set the HTTP status code for this response.
	** 
	** @see `web::WebRes.statusCode`
	abstract Void setStatusCode(Int statusCode)
	
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
	** 
	** @see `web::WebRes.cookies`
	abstract Cookie[] cookies()

	** Return true if this response has been commmited.  A committed response has written its 
	** response headers, and can no longer modify its status code or headers.  A response is 
	** committed the first time that `out` is called.
	** 
	** @see `web::WebRes.isCommitted`
	abstract Bool isCommitted()
	
	** Returns the 'OutStream' for this response. Should current settings allow, the 'OutStream'
	** is automatically gzipped.
	** 
	** @see `web::WebRes.out`
	abstract OutStream out()
	
	** Send a redirect response to the client using the specified status code and url.
	**
	** @see `web::WebRes.redirect`
	abstract Void redirect(Uri uri, Int statusCode)

}

internal const class ResponseImpl : Response {
	
	@Inject
	private const Registry registry

	@Inject
	private const GzipCompressible gzipCompressible

	new make(|This|in) { in(this) } 

	override Void setStatusCode(Int statusCode) {
		webRes.statusCode = statusCode
	}

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
		acceptGzip	:= webReq.headers["Accept-encoding"]?.split(',', true)?.any { it.equalsIgnoreCase("gzip") } ?: false
		doGzip 		:= acceptGzip && gzipCompressible.isCompressible(mimeType)  
		return doGzip ? registry.autobuild(GzipOutStream#) : webRes.out
	}

	override Void redirect(Uri uri, Int statusCode) {
		webRes.redirect(uri, statusCode)
	}
	
	private WebReq webReq() {
		registry.dependencyByType(WebReq#)
	}
	
	private WebRes webRes() {
		registry.dependencyByType(WebRes#)
	}
}