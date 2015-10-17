using afIoc

internal const class T_PageHandler {
	
	@Inject	private const Scope 			scope
	@Inject	private const HttpRequest		request
	@Inject	private const HttpResponse 		response
	@Inject	private const HttpSession 		session
	@Inject	private const BedSheetPages		bedSheetPages

					const Text				fieldResponse := Text.fromPlain("From Field")
	
	new make(|This|in) { in(this) }
	
	// ---- Boom Pages ----

	Void boom() {
		throw Err("BOOM!")
	}
	
	Obj err500() {
		return HttpStatus(500)
	}
	
	Obj iocErr() {
		scope.build(AutoBoom#)
	}
	
	// ---- Buff Pages ----
	
	Obj buff() {
		Text.fromPlain("This is Buff!")
	}

	Obj noBuff() {
		response.disableBuffering = true
		response.headers.contentType = MimeType("text/plain")
		return "This is not Buff!".toBuf.in
	}
	
	// ---- GZIP Pages ----
	
	Obj gzipBig() {
		Text.fromPlain("This is a gzipped message. No really! Need 5 more bytes!")
	}

	Obj gzipSmall() {
		Text.fromPlain("Too small for gzip")
	}
	
	Obj gzipDisable() {
		response.disableGzip = true
		return Text.fromPlain("This is NOT a gzipped message. No really! Need 5 more bytes!")
	}

	// ---- Json Pages ----
	
	Obj list() {
		Text.fromJsonObj("this is a json list".split)
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
	
	Obj noParams() {
		Text.fromPlain("No Params")
	}

	Obj methodCallErr() {
		MethodCall(#noParams, [69])
	}

	Obj defaultParams(Str? p1, Str p2 := "p2", Str p3 := "p3") {
		Text.fromPlain("$p1 $p2 $p3")
	}

	Obj valEnc(Pinky pinky) {
		Text.fromPlain(pinky.int.toStr)
	}
	
	Obj uri(Uri uri) {
		Text.fromPlain("uri: $uri")
	}
	
	// ---- Session Pages ----
	
	Obj countReqs() {
		count := (Int) session.get("count", 0)
		count += 1
		session["count"] = count
		return Text.fromPlain("count $count")
	}
	
	Obj sessionBad() {
		// Params are const but not serialisable
		session["oops"] = #statusCode.params[0]
		return Text.fromPlain("Wot no fail fast Err?")
	}

	Obj sessionBad2() {
		return Text.fromPlain(session["oops"].toStr)
	}
	
	// ---- Status Code Page ----
	
	Obj statusCode(Int httpStatusCode) {
		throw HttpStatusErr(httpStatusCode, "Ooops!")
	}
	
	// ---- Text Pages ----
	
	Obj plain() {
		Text.fromPlain("This is plain text")
	}

	Obj html() {
		Text.fromHtml("This is html text <honest!/>")
	}

	Obj xml() {
		Text.fromXml("This is xml text <honest!/>")
	}

	// ---- Http Request Wrapping ----
	
	Obj httpReq1() {
		Text.fromPlain("On page 1")
	}

	Obj httpReq2() {
		Text.fromPlain("On page 2")
	}
	
	// ---- Dee Dee!!! ----

	Obj deeDee(Uri uri) {
		temp := File.createTemp("DeeDee", uri.toStr).deleteOnExit
		typeof.pod.file(`/res/test/DeeDee.jpg`).copyTo(temp, ["overwrite":true])
		return temp
	}
	
	// ---- save as ----
	
	Obj saveAs(Str saveAs) {
		response.saveAsAttachment(saveAs)
		return Buf().print("Short Skirts!").flip.in
	}

	// ---- Http Flash ----
	
	Obj saveFlashMsg(Str msg) {
		oldMsg := session.flash["msg"]
		session.flash["msg"] = msg
		return Text.fromPlain("Msg = $oldMsg")
	}

	Obj showFlashMsg() {
		oldMsg := session.flash["msg"]
		return Text.fromPlain("Msg = $oldMsg")
	}
	
	// ---- Other ----
	
	Obj renderWelcome() {
		bedSheetPages.renderWelcome
	}
	
	File altFileHandler(Uri remaining) {
		`test/app-web/`.toFile.plus(remaining, false).normalize
	}
	
	Bool slow() {
		response.disableBuffering = true
		response.disableGzip = true
		response.headers.contentLength = Buf().print("OMFG!").size
		response.headers.contentType = MimeType("text/plain")
		concurrent::Actor.sleep(50ms)
		response.out.writeChars("O")
		concurrent::Actor.sleep(50ms)
		response.out.writeChars("M")
		concurrent::Actor.sleep(50ms)
		response.out.writeChars("F")
		concurrent::Actor.sleep(50ms)
		response.out.writeChars("G")
		concurrent::Actor.sleep(50ms)
		response.out.writeChars("!")
		concurrent::Actor.sleep(50ms)
		return true
	}
	
	Obj postForm() {
		str := request.body.form.toCode
		return Text.fromPlain(str)
	}
}

internal class AutoBoom {
	new make() {
		throw Err("AutoBoom!")
	}
}
