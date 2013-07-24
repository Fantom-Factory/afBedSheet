using afIoc::Inject
using afIoc::Registry

internal const class HttpOutStreamGzipBuilder : DelegateChainBuilder {
	@Inject	private const Registry 			registry
	@Inject	private const HttpRequest 		request
	@Inject	private const HttpResponse 		response
	@Inject	private const GzipCompressible 	gzipCompressible

	@Inject @Config { id="afBedSheet.gzip.disabled" }
	private const Bool gzipDisabled

	new make(|This|in) { in(this) } 
	
	override OutStream build(Obj delegate) {
		// do a sanity safety check - someone may have committed the stream behind our backs
		contentType := response.isCommitted ? null : response.headers["Content-Type"]
		mimeType	:= (contentType == null) ? null : MimeType(contentType, false)
		acceptGzip	:= QualityValues(request.headers["Accept-encoding"]).accepts("gzip")
		doGzip 		:= !gzipDisabled && !response.isGzipDisabled && acceptGzip && gzipCompressible.isCompressible(mimeType)		
		return		doGzip ? registry.autobuild(GzipOutStream#, [delegate]) : delegate
	}
}
