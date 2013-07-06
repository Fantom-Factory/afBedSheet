using afIoc::Inject
using afIoc::Registry
using afIoc::ThreadStash
using afIoc::ThreadStashManager
using web::Cookie
using web::WebReq
using web::WebRes
using web::WebOutStream

** An injectable 'const' version of [WebRes]`web::WebRes`.
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
	** 
	** @see `http://en.wikipedia.org/wiki/List_of_HTTP_header_fields#Responses`
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
	
	** Disables gzip compression for this response
	abstract Void disableGzip()
	
	** Send a redirect response to the client using the specified status code and url.
	** If in doubt, use a status code of [303 See Other]`http://en.wikipedia.org/wiki/HTTP_303`.
	**
	** @see `web::WebRes.redirect`
	abstract Void redirect(Uri uri, Int statusCode)

}

internal const class ResponseImpl : Response {
	
	@Inject
	private const Registry registry

	@Inject
	private const GzipCompressible gzipCompressible

	@Inject @Config { id="afBedSheet.gzip.disabled" }
	private const Bool gzipDisabled

	private const ThreadStash threadStash

	new make(ThreadStashManager threadStashManager, |This|in) { 
		in(this) 
		threadStash = threadStashManager.createStash("Response")
	} 

	override Void disableGzip() {
		threadStash["disableGzip"] = true
	}
	
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
		// TODO: afIoc 1.3.10 - Could we make a delegate pipeline?
		contentType := webRes.headers["Content-Type"]
		mimeType	:= MimeType(contentType, false)

		gzipCompressible.isCompressible(mimeType)
		
		encodings	:= QualityValues(webReq.headers["Accept-encoding"])
		acceptGzip	:= encodings.accepts("gzip")
		doGzip 		:= !gzipDisabled && !threadStash.contains("disableGzip") && acceptGzip && gzipCompressible.isCompressible(mimeType)
		webResOut	:= registry.autobuild(WebResOutProxy#)
		bufferedOut	:= registry.autobuild(BufferedOutStream#, [webResOut])
		gzipOut		:= doGzip ? registry.autobuild(GzipOutStream#, [bufferedOut]) : bufferedOut 

		// buffered goes on the inside so content-length is the gzipped size
		return gzipOut
	}

//	scope = perthread
//	OutStream buildResponseOutStream(Type[] delegates) {
//		DelegatePipelineBuilder(OutStream#, delegates)
//	}
	
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
