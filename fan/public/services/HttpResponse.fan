using afIoc::Inject
using afIoc::Registry
using afIoc::ThreadStash
using afIoc::ThreadStashManager
using web::Cookie
using web::WebReq
using web::WebRes

** (Service) - An injectable 'const' version of [WebRes]`web::WebRes`.
** 
** This is proxied and will always refers to the current web response.
const mixin HttpResponse {

	** Get / set the HTTP status code for this response.
	** Setter throws Err if response is already committed.
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
	
	** Return true if this response has been commmited.  A committed response has written its 
	** response headers, and can no longer modify its status code or headers.  A response is 
	** committed the first time that `out` is called.
	** 
	** @see `web::WebRes.isCommitted`
	abstract Bool isCommitted()
	
	** Returns the 'OutStream' for this response. 
	** Should current settings allow, the 'OutStream' is automatically gzipped.
	** 
	** @see `web::WebRes.out`
	abstract OutStream out()
	
	** Set to 'true' to disable gzip compression for this response.
	** 
	** @see `GzipOutStream`
	abstract Bool disableGzip
	
	** Set to 'true' to disable buffering for this response.
	** 
	** @see `BufferedOutStream`
	abstract Bool disableBuffering

	** Directs the client to display a 'save as' dialog. 
	** Sets the 'Content-Disposition' http response header. 
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
	override HttpResponseHeaders headers() 	{ res.headers				}
	override Bool isCommitted() 			{ res.isCommitted			}
	override OutStream out() 				{ res.out					}
	override Void saveAsAttachment(Str fileName) { res.saveAsAttachment(fileName) }
	override Bool disableGzip {
		get { res.disableGzip }
		set { res.disableGzip = it}
	}
	override Bool disableBuffering {
		get { res.disableBuffering }
		set { res.disableBuffering = it}
	}
	override Int statusCode {
		get { res.statusCode }
		set { res.statusCode = it }
	}
}


internal const class HttpResponseImpl : HttpResponse {
	
	@Inject	private const Registry 		registry
	@Inject private const ThreadStash 	threadStash
	override const HttpResponseHeaders	headers

	new make(|This|in) { 
		in(this)
		this.headers = HttpResponseHeaders() |->Str:Str| { webRes.headers }
	} 

	override Bool disableGzip {
		get { threadStash["disableGzip"] ?: false }
		set { threadStash["disableGzip"] = it}
	}
	override Bool disableBuffering {
		get { threadStash["disableBuffering"] ?: false }
		set { threadStash["disableBuffering"] = it}
	}
	override Int statusCode {
		get { webRes.statusCode }
		set { webRes.statusCode = it }
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

