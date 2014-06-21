using util::JsonOutStream

** Return from request handler methods to send a text response to the client. 
** 
** This is purposely a concrete final class so there is no ambiguity as to what it is. For example, 
** if a handler returned an Obj that was both a 'Text' and a 'Redirect' what is BedSheet 
** supposed to do? 
** 
** Best practice is to have your Entities implement a 'toText()' or a 'toJson()' method and return 
** the result of that.
** 
** pre>
** Obj myHandler(MyEntity entity) {
**   ...
**   return entity.toJson
** }
** <pre
** 
** Note: prior to Fantom 1.0.66 the charset will always default to UTF-8 regardless of what Text is
** contructed with. See `http://fantom.org/sidewalk/topic/2166#c13992`.
const final class Text {
	const Str 		text
	const MimeType	contentType
	
	@NoDoc @Deprecated { msg="Use contentType insead" }
	const MimeType	mimeType
	
	private new make(Str text, MimeType contentType) {
		this.text 		 = text
		this.mimeType 	 = contentType
		this.contentType = contentType
	}

	** Creates a 'Text' with the mime type 'text/plain'.
	static new fromPlain(Str text, Charset charset := Charset.utf8) {
		fromMimeStr(text, "text/plain", charset)
	}

	** Creates a 'Text' with the mime type 'text/html'.
	static new fromHtml(Str text, Charset charset := Charset.utf8) {
		fromMimeStr(text, "text/html", charset)
	}

	** Creates a 'Text' with the mime type 'application/xml'.
	static new fromXml(Str text, Charset charset := Charset.utf8) {
		fromMimeStr(text, "application/xml", charset)
	}

	** Creates a 'Text' with the mime type 'application/xhtml+xml'.
	** 
	** Be sure to give your HTML an XML namespace:
	** 
	**   <html xmlns="http://www.w3.org/1999/xhtml"> ... </html>
	** 
	** Or it will **not** be displayed correctly in the browser!  
	static new fromXhtml(Str text, Charset charset := Charset.utf8) {
		fromMimeStr(text, "application/xhtml+xml", charset)
	}

	** Creates a 'Text' with the mime type 'application/json'.
	** 'jsonObj' should be serialisable into Json via `util::JsonOutStream`
	static new fromJson(Obj jsonObj, Charset charset := Charset.utf8) {
		json := JsonOutStream.writeJsonToStr(jsonObj)
		return fromMimeStr(json, "application/json", charset)
	}

	** Creates a 'Text' with the mime type 'application/json'.
	** The json is wrapped in the given callback function name. 
	** 'jsonObj' should be serialisable into Json via `util::JsonOutStream`.
	static new fromJsonP(Obj jsonObj, Str callbackFuncName, Charset charset := Charset.utf8) {
		json := JsonOutStream.writeJsonToStr(jsonObj)
		text := "${callbackFuncName}(${json});"
		return fromMimeStr(text, "application/json", charset)
	}

	** Creates a 'Text' with the given mime type.
	static new fromMimeType(Str text, MimeType mimeType) {
		Text.make(text, mimeType)
	}

	private static new fromMimeStr(Str text, Str mimeType, Charset charset) {
		Text.make(text, MimeType.fromStr("$mimeType; charset=${charset.name}"))		
	}
	
	override Str toStr() {
		"${contentType.mediaType}/${contentType.subType}::${text}"
	}
}
