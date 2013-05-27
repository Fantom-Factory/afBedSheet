
internal const class GzipPage {
	
	Obj gzipBig() {
		TextResult.fromPlain("This is a gzipped message. No really! Need 5 more bytes!")
	}

	Obj gzipSmall() {
		TextResult.fromPlain("Too small for gzip")
	}
	
}
