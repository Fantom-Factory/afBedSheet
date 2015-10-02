using afIoc3::Inject
using web::WebRes

** Wraps the 'WebRes.out' stream so we can pass references of it around without committing the 
** response.
internal class WebResOutProxy : OutStream {
	
	@Inject
	private WebRes 		webRes
	
	private new make(|This|in) : super(null) {
		in(this)
	}
	
	override This write(Int byte) {
		webRes.out.write(byte)
		return this
	}

	override This writeBuf(Buf buf, Int n := buf.remaining()) {
		webRes.out.writeBuf(buf, n)
		return this
	}
	
	override This flush() {
		webRes.out.flush
		return this
	}
	
	override Bool close() {
		webRes.out.close
	}
}
