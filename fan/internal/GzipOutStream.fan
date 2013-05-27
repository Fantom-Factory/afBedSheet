using afIoc::Inject
using web::WebRes

// TODO: make comment neater
//What is recommended minimum object size for gzip performance benefits?
// http://webmasters.stackexchange.com/questions/31750/what-is-recommended-minimum-object-size-for-gzip-performance-benefits
// google 100-1000 - https://developers.google.com/speed/docs/best-practices/payload#GzipCompression
// webpacket 860 
// http://en.wikipedia.org/wiki/Maximum_transmission_unit
// IPv4 at least 576
// IPv6 1280
// MTU for whole res inc header text, so say avg MAX header text = 200, threshold 376
// Note T5=100
internal class GzipOutStream : OutStream {
	
	private WebRes webRes
	private Buf buf := Buf()
	
	@Inject @Config { id="afBedSheet.gzip.disabled" }
	private Bool gzipDisabled

	@Inject @Config { id="afBedSheet.gzip.threshold" }
	private Int gzipThreadhold
	
	new make(WebRes webRes, |This|in) : super(null) {
		in(this)
		this.webRes = webRes
	}
	
	override This write(Int byte) {
		buf.out.write(byte)
		return this
	}

	override This writeBuf(Buf buf, Int n := buf.remaining()) {
		buf.out.writeBuf(buf, n)
		return this
	}
	
	override Bool close() {
		outBuf := buf
		
		if (!gzipDisabled && buf.size >= gzipThreadhold) {
			webRes.headers["Content-Encoding"] = "gzip"
			outBuf = Buf()
			Zip.gzipOutStream(outBuf.out).writeBuf(buf)
		}
		
		webRes.headers["Content-Length"] = outBuf.size.toStr
		webRes.out.writeBuf(outBuf)		
		webRes.out.close
		return true
	}
}
