using util::JsonOutStream

@Deprecated { msg="Use Text instead" } @NoDoc
const final class TextResponse {
	const Str 		text
	const MimeType	mimeType
	
	private new make(Str text, MimeType mimeType) {
		this.text = text
		this.mimeType = mimeType
	}

	** Use `Text` instead
	static new fromPlain(Str text, Charset charset := Charset.utf8) {
		fromMimeStr(text, "text/plain", charset)
	}

	** Use `Text` instead
	static new fromHtml(Str text, Charset charset := Charset.utf8) {
		fromMimeStr(text, "text/html", charset)
	}

	** Use `Text` instead
	static new fromXml(Str text, Charset charset := Charset.utf8) {
		fromMimeStr(text, "text/xml", charset)
	}

	** Use `Text` instead
	static new fromJson(Obj jsonObj, Charset charset := Charset.utf8) {
		json := JsonOutStream.writeJsonToStr(jsonObj)
		return fromMimeStr(json, "application/json", charset)
	}

	** Use `Text` instead
	static new fromJsonP(Obj jsonObj, Str callbackFuncName, Charset charset := Charset.utf8) {
		json := JsonOutStream.writeJsonToStr(jsonObj)
		text := "${callbackFuncName}(${json});"
		return fromMimeStr(text, "application/json", charset)
	}

	** Use `Text` instead
	static new fromMimeType(Str text, MimeType mimeType) {
		TextResponse.make(text, mimeType)
	}

	private static new fromMimeStr(Str text, Str mimeType, Charset charset) {
		TextResponse.make(text, MimeType.fromStr("$mimeType; charset=${charset.name}"))		
	}
}
