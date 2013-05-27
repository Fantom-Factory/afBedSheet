using afIoc::Inject
using web::WebRes

** At what point do we start gzipping our response?
** 
** Well Google reccomend between [100 -> 1,000 bytes]`https://developers.google.com/speed/docs/best-practices/payload#GzipCompression` 
** which is quite a bit gap. Tapestry 5 sets it's default to an agressive 100.
**  
** So looking into [Maximum Transmission Units]`http://en.wikipedia.org/wiki/Maximum_transmission_unit`
** it seems for IPv4 it is at least 576 bytes and for IPv6 it a maximum of 1280 bytes. The MTU 
** would also have to include the http header text which, looking at WISP responses, seem to be 
** 150 -> 200 bytes. Simple maths is then:
** 
**     576 - 200 = 376
**  
** So the default GZIP threshold is set to 376. Although you should still inspect your site traffic 
** and adjust accordingly.
** 
** @see [What is recommended minimum object size for gzip performance benefits?]`http://webmasters.stackexchange.com/questions/31750/what-is-recommended-minimum-object-size-for-gzip-performance-benefits`
internal class GzipOutStream : OutStream {
	
	private WebRes webRes
	private Buf webBuf := Buf()
	
	@Inject @Config { id="afBedSheet.gzip.disabled" }
	private Bool gzipDisabled

	@Inject @Config { id="afBedSheet.gzip.threshold" }
	private Int gzipThreadhold
	
	new make(WebRes webRes, |This|in) : super(null) {
		in(this)
		this.webRes = webRes
	}
	
	override This write(Int byte) {
		webBuf.write(byte)
		return this
	}

	override This writeBuf(Buf buf, Int n := buf.remaining()) {
		webBuf.writeBuf(buf, n)
		return this
	}
	
	override This flush() {
		webBuf.flush
		return this
	}
	
	// TODO: Don't wait until we close the stream before we start gzipping - we can do it dynamically.  
	override Bool close() {
		outBuf := webBuf
		
		if (!gzipDisabled && webBuf.size >= gzipThreadhold) {
			webRes.headers["Content-Encoding"] = "gzip"
			
			outBuf = Buf()
			gzipOut := Zip.gzipOutStream(outBuf.out)
			gzipOut.writeBuf(webBuf.flip)
			gzipOut.flush
			gzipOut.close
		}
		
		webRes.headers["Content-Length"] = outBuf.size.toStr
		webRes.out.writeBuf(outBuf.flip)
		webRes.out.flush
		webRes.out.close
		return true
	}
}
