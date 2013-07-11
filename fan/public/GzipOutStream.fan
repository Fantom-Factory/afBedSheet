using afIoc::Inject
using web::WebRes

** A stream that starts gzipping once data has accumulated past a given (minimum) threshold. When 
** the stream turns gzip, the HTTP 'Content-Encoding' header is set in the `Response`.
** 
** But at what point do we start gzipping our response?
** 
** Well Google recommend between [100 -> 1,000 bytes]`https://developers.google.com/speed/docs/best-practices/payload#GzipCompression` 
** which is quite a bit gap. Tapestry 5 sets its default to an agressive 100 bytes.
**  
** So looking into [Maximum Transmission Units]`http://en.wikipedia.org/wiki/Maximum_transmission_unit`
** it seems for IPv4 it is at least 576 bytes and for IPv6 it a maximum of 1280 bytes. The MTU 
** would also have to include the http header text which, looking at WISP responses, seem to be 
** 150 -> 200 bytes. Simple math is then:
** 
**     576 - 200 = 376
**  
** So the default GZIP threshold is set to 376. Although you should still inspect your site traffic 
** and adjust accordingly.
** 
** @see `ConfigIds.gzipThreshold`
** 
** @see [What is recommended minimum object size for gzip performance benefits?]`http://webmasters.stackexchange.com/questions/31750/what-is-recommended-minimum-object-size-for-gzip-performance-benefits`
class GzipOutStream : OutStream {

	// We start by piping all data to the OutStream of an internal Buf. When that exceeds the 
	// given gzip threshold, we switch to piping to gzip wrapped res.out. 
	
	@Inject @Config { id="afBedSheet.gzip.threshold" }
	private Int 		gzipThreadhold
	
	@Inject
	private WebRes		response
	
	private OutStream	wrappedOut
	private Bool		switched
	private Buf? 		buf
	private OutStream? 	bufOut
	private OneShotLock	lock

	private new make(OutStream wrappedOut, |This|in) : super(null) {
		in(this)
		this.wrappedOut	= wrappedOut
		this.lock 		= OneShotLock("Stream is closed")
	}
	
	override This write(Int byte) {
		lock.check
		switchToGzip(1)
		bufOut.write(byte)
		return this
	}

	override This writeBuf(Buf buf, Int n := buf.remaining()) {
		lock.check
		switchToGzip(n)
		bufOut.writeBuf(buf, n)
		return this
	}
	
	override This flush() {
		lock.check
		bufOut?.flush
		return this
	}
	
	override Bool close() {
		// check lock, cos we should be able to call 'close()' more than once
		if (lock.isLocked)
			return true
		
		lock.lock

		if (!switched) {
			bufOut = wrappedOut
			writeBufToOut
		}
		
		bufOut.flush
		bufOut.close
		return true
	}

	private Void switchToGzip(Int noOfBytes) {
		if (switched)
			return
		
		if (((buf?.size ?: 0) + noOfBytes) > gzipThreadhold) {
			if (!response.isCommitted)	// a sanity check
				response.headers["Content-Encoding"] = "gzip"	
			bufOut = Zip.gzipOutStream(wrappedOut)
			writeBufToOut
			switched = true
			return
		}
		
		// wait until last minute before creating a buf
		if (buf == null) {
			buf		= Buf(gzipThreadhold)
			bufOut 	= buf.out
		}
	}

	private Void writeBufToOut() {
		// when we close the stream, we may not have written anything
		if (buf != null) {
			bufOut.writeBuf(buf.flip)
			buf.close
		}
		switched = true
	}
}
