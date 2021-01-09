using afIoc::Inject
using web::Cookie
using web::WebRes
using concurrent::Actor
using web::WebUtil

** (Service) - An injectable 'const' version of [WebRes]`web::WebRes`.
** 
** This will always refers to the current web response.
const mixin HttpResponse {

	** Get / set the HTTP status code for this response.
	** Setter throws Err if response is already committed.
	** 
	** @see `web::WebRes.statusCode`
	abstract Int statusCode
	
	** Map of HTTP response headers.  You must set all headers before you access out() for the 
	** first time, which commits the response.  
	** 
	** @see 
	**  - `web::WebRes.headers`
	**  - `http://en.wikipedia.org/wiki/List_of_HTTP_header_fields#Responses`
	abstract HttpResponseHeaders headers()
	
	** Return true if this response has been committed.  A committed response has written its 
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
	abstract Bool disableGzip
	
	** Set to 'true' to disable buffering for this response.
	** 
	** Buffered responses contain a 'Content-Length' header and are easier to process by clients. 
	** Non buffered responses are streamed straight out to the client.
	abstract Bool disableBuffering

	** Directs the client to display a 'save as' dialog by setting the 'Content-Disposition' HTTP 
	** response header. 
	** 
	** The 'Content-Type' HTTP response header is set to the MimeType derived from the fileName's 
	** extension.
	** 
	** @see `HttpResponseHeaders.contentDisposition`
	abstract Void saveAsAttachment(Str fileName)
	
	** Adds an event handler that gets called just before a session is committed.
	** Use to make last minute changes to header values. 
	** 
	** Callbacks may be mutable, do not need to be cleaned up, but should be added at the start of *every* HTTP request. 
	abstract Void onCommit(|HttpResponse| fn)
	
	** Clears all response headers and sets the status code back to '200'.
	** 
	** Called by BedSheet before processing an error handler.
	** 
	** Throws an Err should the response already be committed.
	@NoDoc	// advanced use only!
	abstract Void reset()

	** Map of HTTP status codes to status messages.
	** 
	** See [WebRes.statusMsg]`web::WebRes.statusMsg`.
	static const Int:Str statusMsg := WebRes.statusMsg.rw.setAll([
		// @see http://fantom.org/forum/topic/2683#c1
		203 : "Non-Authoritative Information",
		308	: "Permanent Redirect",
		418 : "I'm a teapot",
	])
}

internal const class HttpResponseImpl : HttpResponse {
	@Inject  const |->RequestState|		reqState
	new make(|This|in) { 
		in(this)
	} 
	override HttpResponseHeaders headers() {
		reqState().responseHeaders
	}
	override Bool disableGzip {
		get { reqState().disableGzip ?: false }
		set { reqState().disableGzip = it}
	}
	override Bool disableBuffering {
		get { reqState().disableBuffering ?: false }
		set { reqState().disableBuffering = it}
	}
	override Int statusCode {
		get { reqState().webRes.statusCode }
		set { reqState().webRes.statusCode = it }
	}	
	override Bool isCommitted() {
		reqState().webRes.isCommitted
	}
	override OutStream out() {
		reqState().responseBody
	}
	override Void saveAsAttachment(Str fileName) {
		headers.contentDisposition = "attachment; filename=" + WebUtil.toQuotedStr(fileName)
		headers.contentType = fileName.toUri.mimeType
	}
	override Void onCommit(|HttpResponse| fn) {
		reqState().addResponseCommitFn(fn)
	}
	override Void reset() {
		headers.clear
		statusCode = 200
		disableGzip = false
		disableBuffering = false
	}
	override Str toStr() {
		"$statusCode ${statusMsg[statusCode]}"
	}
}

