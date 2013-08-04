using afIoc::Inject
using afIoc::Registry
using afIoc::ThreadStash
using afIoc::ThreadStashManager
using web::Cookie
using web::WebReq
using web::WebRes

** An injectable 'const' version of [WebRes]`web::WebRes`.
** 
** This is proxied and will always refers to the current web response.
// FIXME: set some fields!
const mixin HttpResponse {

	** Set the HTTP status code for this response.
	** 
	** @see `web::WebRes.statusCode`
	abstract Int statusCode
	
	** Map of HTTP response headers.  You must set all headers before you access out() for the 
	** first time, which commits the response. Throws Err if response is already committed. 
	** 
	** @see 
	**  - `web::WebRes.headers`
	**  - `http://en.wikipedia.org/wiki/List_of_HTTP_header_fields#Responses`
	abstract HttpResponseHeaders headers()
	
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
	
	** Directs the client to display a 'save as' dialog. Sets the 'Content-Disposition' http 
	** response header. 
	** 
	** Don't forget to set the 'Content-Type' header too!
	** 
	** @see `HttpResponseHeaders.contentDisposition`
	abstract Void saveAsAttachment(Str fileName)
}

** Wraps a given `HttpResponse`, delegating all its methods. 
** You may find it handy to use when contributing to the 'HttpResponse' delegate chain.
@NoDoc
const class HttpResponseWrapper : HttpResponse {
	const 	 HttpResponse res
	new 	 make(HttpResponse res) 		{ this.res = res 			} 
	override Void disableGzip()				{ res.disableGzip			}
	override Bool isGzipDisabled() 			{ res.isGzipDisabled		}
	override Void disableBuffering() 		{ res.disableBuffering		}
	override Bool isBufferingDisabled() 	{ res.isBufferingDisabled	}
	override HttpResponseHeaders headers() 	{ res.headers				}
	override Cookie[] cookies() 			{ res.cookies				}
	override Bool isCommitted() 			{ res.isCommitted			}
	override OutStream out() 				{ res.out					}
	override Void saveAsAttachment(Str fileName) { res.saveAsAttachment(fileName) }
	override Int statusCode {
		get { res.statusCode }
		set { res.statusCode = it }
	}
}


internal const class HttpResponseImpl : HttpResponse {
	
	@Inject	private const Registry 	registry
	
	private const ThreadStash threadStash

	new make(ThreadStashManager threadStashManager, |This|in) { 
		in(this) 
		threadStash = threadStashManager.createStash("HttpResponse")
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
	
	override Int statusCode {
		get { webRes.statusCode }
		set { webRes.statusCode = it }
	}	

	override HttpResponseHeaders headers() {
		threadStash.get("headers") |->Obj| { HttpResponseHeaders(webRes.headers) }
	}

	override Cookie[] cookies() {
		webRes.cookies
	}

	override Bool isCommitted() {
		webRes.isCommitted
	}
	
	override OutStream out() {
		registry.serviceById("HttpOutStream")
	}
	
	override Void saveAsAttachment(Str fileName) {
		headers.contentDisposition = "Attachment; filename=${fileName}"
	}

	private WebRes webRes() {
		registry.dependencyByType(WebRes#)
	}	
}

