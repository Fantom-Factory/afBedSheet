using afIoc::Inject

internal const class T_PageHandler {
	
	@Inject	private const HttpResponse response
	@Inject	private const HttpSession session
	
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
	
	// ---- Redirect Pages ----

	Obj redirectPerm() {
		Redirect.movedPermanently(`/movedPermanently`)
	}

	Obj redirectTemp() {
		Redirect.movedTemporarily(`/movedTemporarily`)
	}
	
	Obj afterPost() {
		Redirect.afterPost(`/afterPost`)
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

	// ---- Session Pages ----
	
	Obj countReqs() {
		count := (Int) session.get("count", 0)
		count += 1
		session["count"] = count
		return TextResponse.fromPlain("count $count")
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

	// ---- Http Request Wrapping ----
	
	Obj httpReq1() {
		TextResponse.fromPlain("On page 1")
	}

	Obj httpReq2() {
		TextResponse.fromPlain("On page 2")
	}
	
	// ---- Dee Dee!!! ----

	Obj deeDee(Uri uri) {
		temp := File.createTemp("DeeDee", uri.toStr).deleteOnExit
		typeof.pod.file(`/res/test/DeeDee.jpg`).copyTo(temp, ["overwrite":true])
		return temp
	}
}
