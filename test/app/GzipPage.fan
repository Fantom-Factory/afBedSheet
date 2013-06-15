using afIoc::Inject

internal const class GzipPage {

	@Inject
	private const Response response
	
	new make(|This|in) { in(this) }
	
	Obj gzipBig() {
		TextResult.fromPlain("This is a gzipped message. No really! Need 5 more bytes!")
	}

	Obj gzipSmall() {
		TextResult.fromPlain("Too small for gzip")
	}
	
	Obj gzipDisable() {
		response.disableGzip
		return TextResult.fromPlain("This is NOT a gzipped message. No really! Need 5 more bytes!")
	}
	
}
