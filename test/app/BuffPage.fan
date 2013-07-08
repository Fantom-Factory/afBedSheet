using afIoc::Inject

const class BuffPage {
	
	@Inject
	private const HttpResponse response
	
	new make(|This|in) { in(this) }
	
	Obj buff() {
		TextResponse.fromPlain("This is Buff!")
	}

	Obj noBuff() {
		response.disableBuffering
		return TextResponse.fromPlain("This is not Buff!")
	}
}
