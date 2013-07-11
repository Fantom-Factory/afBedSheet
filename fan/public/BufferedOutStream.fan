using afIoc::Inject
using web::WebRes

** A stream that buffers its contents starts gzipping once data has accumulated past a given (minimum) threshold. When 
internal class BufferedOutStream : OutStream {

	@Config { id="afBedSheet.responseBuffer.threshold" }
	@Inject private Int 			resBufThreadhold	
	@Inject	private HttpResponse	response
	
	private OutStream	realOut
	private Bool		switched
	private Buf? 		buf
	private OutStream? 	bufOut
	private OneShotLock	lock

	private new make(OutStream realOut, |This|in) : super(null) {
		in(this) 
		this.realOut 	= realOut
		this.lock		= OneShotLock("Stream is closed")
	}

	override This write(Int byte) {
		lock.check
		switchToReal(1)
		bufOut.write(byte)
		return this
	}

	override This writeBuf(Buf buf, Int n := buf.remaining()) {
		lock.check
		switchToReal(n)
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

		// we're hoping we've not switched yet - the whole point of this class is to write the 
		// 'Content-Length' header!
		if (!switched) {
			if (!response.isCommitted)	// a sanity check
				response.headers["Content-Length"] = (buf?.size ?: 0).toStr
			bufOut = realOut
			writeBufToOut
		}
		
		bufOut.flush
		bufOut.close
		return true
	}

	private Void switchToReal(Int noOfBytes) {
		if (switched)
			return
		
		if (((buf?.size ?: 0) + noOfBytes) > resBufThreadhold) {
			switched = true
			bufOut = realOut
			writeBufToOut
			return
		}
		
		// wait until last minute before creating a buf
		// if the first write is bigger than our threshold, then we write straight to the real out 
		if (buf == null) {
			buf		= Buf(resBufThreadhold)
			bufOut 	= buf.out
		}
	}

	private Void writeBufToOut() {
		// when we close the stream, we may not have written anything
		if (buf != null) {
			bufOut.writeBuf(buf.flip)
			buf.close
		}
	}
}