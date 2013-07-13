using afIoc::Inject

internal const class T_PageHandler {
	
	@Inject
	private const HttpResponse response
	
	new make(|This|in) { in(this) }
	
	// ---- Boom Pages ----

	Void boom() {
		throw Err("BOOM!")
	}
	
	// ---- Buff Pages ----
	
	Obj buff() {
		TextResponse.fromPlain("This is Buff!")
	}

	Obj noBuff() {
		response.disableBuffering
		return TextResponse.fromPlain("This is not Buff!")
	}
	
	// ---- CORS Pages ----
	
	TextResponse simple() {
		TextResponse.fromPlain("CORS!")
	}

	TextResponse preflight() {
		TextResponse.fromPlain("Preflight!")
	}
	
	// ---- GZIP Pages ----
	
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

	// ---- Json Pages ----
	
	Obj list() {
		TextResponse.fromJson("this is a json list".split)
	}
	
	// ---- Route Pages ----
	
	Obj defaultParams(Str p1, Str p2 := "p2", Str p3 := "p3") {
		TextResponse.fromPlain("$p1 $p2 $p3")
	}

	Obj valEnc(Pinky pinky) {
		TextResponse.fromPlain(pinky.int.toStr)
	}
	
	Obj uri(Uri uri) {
		TextResponse.fromPlain("uri: $uri")
	}
	
	// ---- Status Code Page ----
	
	Obj statusCode(Int httpStatusCode) {
		throw HttpStatusErr(httpStatusCode, "Ooops!")
	}
	
	// ---- Text Pages ----
	
	Obj plain() {
		TextResponse.fromPlain("This is plain text")
	}

	Obj html() {
		TextResponse.fromHtml("This is html text <honest!/>")
	}

	Obj xml() {
		TextResponse.fromXml("This is xml text <honest!/>")
	}

}
