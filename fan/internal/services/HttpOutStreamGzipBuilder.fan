using afIoc::Inject
using afIoc::Registry
using afIocConfig::Config

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
		contentType := response.isCommitted ? null : response.headers.contentType
		acceptGzip	:= request.headers.acceptEncoding?.accepts("gzip") ?:false
		doGzip 		:= !gzipDisabled && !response.disableGzip && acceptGzip && gzipCompressible.isCompressible(contentType)		
		return		doGzip ? registry.autobuild(GzipOutStream#, [delegate]) : delegate
	}
}
