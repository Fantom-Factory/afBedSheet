using afIoc::Inject

internal const class GzipPage {

	@Inject
	private const Response response
	
	new make(|This|in) { in(this) }
	
	Obj gzipBig() {
		TextResponse.fromPlain("This is a gzipped message. No really! Need 5 more bytes!")
	}

	Obj gzipSmall() {
		TextResponse.fromPlain("Too small for gzip")
	}
	
	Obj gzipDisable() {
		response.disableGzip
		return TextResponse.fromPlain("This is NOT a gzipped message. No really! Need 5 more bytes!")
	}
	
}
