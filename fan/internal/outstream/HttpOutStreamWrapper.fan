using afIoc::Inject
using afIoc::Scope
using afIocConfig::Config

internal const class HttpOutStreamWrapper {
	@Inject private const |->Scope|			scopeFn
	@Inject	private const HttpRequest		request
	@Inject	private const HttpResponse 		response
	@Inject	private const GzipCompressible 	gzipCompressible
	@Config { id="afBedSheet.gzip.disabled" }
	@Inject private const Bool 				gzipDisabled
	
	new make(|This| f) { f(this) }

	OutStream safeWrapper(Obj delegate) {
		HttpOutStreamSafe(delegate)
	}

	OutStream bufferedWrapper(Obj delegate) {
		response.disableBuffering
			? delegate
			: scopeFn().build(HttpOutStreamBuffered#, [delegate])
	}

	OutStream gzipWrapper(Obj delegate) {
		// if the response *could* be gzipped, then set the vary header
		// see http://blog.maxcdn.com/accept-encoding-its-vary-important/
		if (!gzipDisabled && !response.isCommitted && response.headers.vary == null)
			response.headers.vary = "Accept-Encoding"
		
		// do a sanity safety check - someone may have committed the stream behind our backs
		contentType := response.isCommitted ? null : response.headers.contentType
		acceptGzip	:= request.headers.acceptEncoding?.accepts("gzip") ?: false
		doGzip 		:= !gzipDisabled && !response.disableGzip && acceptGzip && gzipCompressible.isCompressible(contentType)		
		return		doGzip ? scopeFn().build(HttpOutStreamGzip#, [delegate]) : delegate
	}
	
	OutStream onCommitWrapper(Obj delegate) {
		scopeFn().build(HttpOutStreamOnCommit#, [delegate])
	}
}
