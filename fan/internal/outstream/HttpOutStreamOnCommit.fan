using afIoc::Inject
using web::WebRes

internal class HttpOutStreamOnCommit : OutStream {
	
	@Inject	private RequestState	requestState
	@Inject	private HttpResponse 	httpResponse
			private OutStream		realOut
			private Bool			firedEvent

	new make(OutStream realOut, |This| f) : super(null) {
		f(this)
		this.realOut 	= realOut
	}

	override This write(Int byte) {
		// this works because wisp::WebRes writes the headers out for us when 'out' is referenced.
		// 'out' is only truely referenced by BedSheet in the WebResOutProxy when data is finally written to it.
		// so here is out last chance to change the headers!
		if (!firedEvent) {
			requestState.fireResponseCommit(httpResponse)
			firedEvent = true
		}
		realOut.write(byte)
		return this
	}

	override This writeBuf(Buf buf, Int n := buf.remaining()) {
		if (!firedEvent) {
			requestState.fireResponseCommit(httpResponse)
			firedEvent = true
		}
		realOut.writeBuf(buf, n)
		return this
	}
	
	override This flush() {
		realOut.flush
		return this
	}
	
	override Bool close() {
		realOut.close
	}
}
