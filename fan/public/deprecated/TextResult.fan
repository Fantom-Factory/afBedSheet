
@Deprecated { msg="Use 'TextResponse' instead" }
const final class TextResult { 
	
	@Deprecated { msg="Use 'TextResponse' instead" }
	static TextResponse fromPlain(Str text) {
		TextResponse.fromPlain(text)
	}

	@Deprecated { msg="Use 'TextResponse' instead" }
	static TextResponse fromHtml(Str text) {
		TextResponse.fromHtml(text)
	}

	@Deprecated { msg="Use 'TextResponse' instead" }
	static TextResponse fromXml(Str text) {
		TextResponse.fromXml(text)
	}

	@Deprecated { msg="Use 'TextResponse' instead" }
	static TextResponse fromJson(Obj jsonObj) {
		return TextResponse.fromJson(jsonObj)		
	}
	
	@Deprecated { msg="Use 'TextResponse' instead" }
	static TextResponse fromJsonP(Obj jsonObj, Str callbackFuncName) {
		return TextResponse.fromJsonP(jsonObj, callbackFuncName)
	}
	
	@Deprecated { msg="Use 'TextResponse' instead" }
	static TextResponse fromMimeType(Str text, MimeType mimeType) {
		TextResponse.fromMimeType(text, mimeType)
	}	
}
