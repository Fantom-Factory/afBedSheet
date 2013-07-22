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
** This is proxied and will always refers to the current web response.
const mixin HttpResponse {

	** Set the HTTP status code for this response.
	** 
	** @see `web::WebRes.statusCode`
	abstract Void setStatusCode(Int statusCode)
	
	** Map of HTTP response headers.  You must set all headers before you access out() for the 
	** first time, which commits the response. Throws Err if response is already committed. 
	** 
	** @see 
	**  - `web::WebRes.headers`
	**  - `http://en.wikipedia.org/wiki/List_of_HTTP_header_fields#Responses`
	abstract Str:Str headers()
	
	** Get the list of cookies to set via header fields.  Add a Cookie to this list to set a 
	** cookie.  Throws Err if response is already committed.
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
	
	** Disables gzip compression for this response.
	** 
	** @see `GzipOutStream`
	abstract Void disableGzip()
	
	** Has gzip compression been disabled for this response? 
	** Only returns 'true' if 'disableGzip()' has been called.
	** 
	** @see `GzipOutStream`
	abstract Bool isGzipDisabled()	

	** Disables response buffering
	** 
	** @see `BufferedOutStream`
	abstract Void disableBuffering()

	** Has response buffering been disabled for this response?
	** Only returns 'true' if 'disableBuffering()' has been called.
	** 
	** @see `BufferedOutStream`
	abstract Bool isBufferingDisabled()
}

internal const class HttpResponseImpl : HttpResponse {
	
	@Inject	private const Registry 			registry
	
//	@Inject	private const HttpRequest 		request
//	@Inject	private const GzipCompressible 	gzipCompressible

//	@Inject @Config { id="afBedSheet.gzip.disabled" }
//	private const Bool gzipDisabled

	private const ThreadStash threadStash

	new make(ThreadStashManager threadStashManager, |This|in) { 
		in(this) 
		threadStash = threadStashManager.createStash("Response")
	} 

	override Void disableGzip() {
		threadStash["disableGzip"] = true
	}

	override Bool isGzipDisabled() {
		threadStash.contains("disableGzip")		
	}
	
	override Void disableBuffering() {
		threadStash["disableBuffering"] = true
	}
	
	override Bool isBufferingDisabled() {
		threadStash.contains("disableBuffering")		
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
		registry.serviceById("HttpOutStream")
		
//		out := threadStash["out"]
//		if (out != null)
//			return out
//
//		// TODO: afIoc 1.3.10 - Could we make a delegate pipeline?
//		contentType := headers["Content-Type"]
//		mimeType	:= (contentType == null) ? null : MimeType(contentType, false)
//		acceptGzip	:= QualityValues(request.headers["Accept-encoding"]).accepts("gzip")
//		doGzip 		:= !gzipDisabled && !threadStash.contains("disableGzip") && acceptGzip && gzipCompressible.isCompressible(mimeType)
//		doBuff		:= !threadStash.contains("disableBuffering")
//		webResOut	:= registry.autobuild(WebResOutProxy#)
//		bufferedOut	:= doBuff ? registry.autobuild(BufferedOutStream#, [webResOut]) : webResOut 
//		gzipOut		:= doGzip ? registry.autobuild(GzipOutStream#, [bufferedOut]) : bufferedOut 
//		
//		threadStash["out"] = gzipOut
//		
//		// buffered goes on the inside so content-length is the gzipped size
//		return gzipOut
	}

//	@Build { serviceId="HttpOutStream"; scope=ServiceScope.perthread }
//	OutStream buildHttpOutStream(HttpOutStreamBuilder[] delegates) {
//		DelegateBuilder.build(OutStream#, delegates, terminator)
//	}

	private WebRes webRes() {
		registry.dependencyByType(WebRes#)
	}
}

const class DelegateServiceBuilder {
	Obj build(DelegateChainBuilder[] delegateBuilders, Obj service) {
		delegateBuilders.reduce(service) |Obj delegate, DelegateChainBuilder builder| { builder.build(delegate) }
	}
}

const mixin DelegateChainBuilder {
	abstract Obj build(Obj delegate) 
}


const class HttpOutStreamGzipBuilder : DelegateChainBuilder {
	@Inject	private const Registry 			registry
	@Inject	private const HttpRequest 		request
	@Inject	private const HttpResponse 		response
	@Inject	private const GzipCompressible 	gzipCompressible

	@Inject @Config { id="afBedSheet.gzip.disabled" }
	private const Bool gzipDisabled

	new make(|This|in) { in(this) } 
	
	override OutStream build(Obj delegate) {
		contentType := response.headers["Content-Type"]
		mimeType	:= (contentType == null) ? null : MimeType(contentType, false)
		acceptGzip	:= QualityValues(request.headers["Accept-encoding"]).accepts("gzip")
		doGzip 		:= !gzipDisabled && !response.isGzipDisabled && acceptGzip && gzipCompressible.isCompressible(mimeType)		
		return		doGzip ? registry.autobuild(GzipOutStream#, [delegate]) : delegate
	}
}

const class HttpOutStreamBuffBuilder : DelegateChainBuilder {
	@Inject	private const Registry 			registry
	@Inject	private const HttpResponse 		response

	new make(|This|in) { in(this) } 
	
	override OutStream build(Obj delegate) {
		doBuff	:= !response.isBufferingDisabled
		return	doBuff ? registry.autobuild(BufferedOutStream#, [delegate]) : delegate 
	}
}
