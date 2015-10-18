using util::JsonOutStream

** (Response Object) - 
** Use to send a text response to the client. 
** 
**   syntax: fantom
**   Text.fromHtml("<html>Hello!<html>")
** 
** This is purposely a concrete final class so there is no ambiguity as to what it is. For example, 
** if a handler returned an Obj that was both a 'Text' and a 'Redirect' what is BedSheet 
** supposed to do? 
** 
** Best practice is to have your Entities implement a 'toText()' or a 'toJson()' method and return 
** the result of that.
** 
** pre>
** syntax: fantom
** Text myHandler(MyEntity entity) {
**   ...
**   return entity.toJson
** }
** <pre
** 
** Note: prior to Fantom 1.0.66 the charset would always default to UTF-8 regardless of what Text is
** constructed with. See `http://fantom.org/sidewalk/topic/2166#c13992`.
const final class Text {
	const Str 		text
	const MimeType	contentType
	
	private new make(Str text, MimeType contentType) {
		this.text 		 = text
		this.contentType = contentType
	}

	** Creates a 'Text' with the mime type 'text/plain'.
	static new fromPlain(Str text, Charset charset := Charset.utf8) {
		_fromMimeStr(text, "text/plain", charset)
	}

	** Creates a 'Text' with the mime type 'text/html'.
	static new fromHtml(Str html, Charset charset := Charset.utf8) {
		_fromMimeStr(html, "text/html", charset)
	}

	** Creates a 'Text' with the mime type 'application/xml'.
	static new fromXml(Str xml, Charset charset := Charset.utf8) {
		_fromMimeStr(xml, "application/xml", charset)
	}

	** Creates a 'Text' with the mime type 'application/xhtml+xml'.
	** 
	** Be sure to give your XHTML an XML namespace:
	** 
	**   <html xmlns="http://www.w3.org/1999/xhtml"> ... </html>
	** 
	** Or it will **not** be displayed correctly in the browser!  
	static new fromXhtml(Str xhtml, Charset charset := Charset.utf8) {
		_fromMimeStr(xhtml, "application/xhtml+xml", charset)
	}

	** Creates a 'Text' from the given 'Str' with the mime type 'application/json'.
	static new fromJson(Str json, Charset charset := Charset.utf8) {
		return _fromMimeStr(json, "application/json", charset)
	}

	** Creates a 'Text' with the mime type 'application/json'.
	** 'jsonObj' should be serialisable into Json via `util::JsonOutStream`
	static new fromJsonObj(Obj jsonObj, Charset charset := Charset.utf8) {
		json := JsonOutStream.writeJsonToStr(jsonObj)
		return _fromMimeStr(json, "application/json", charset)
	}

	** Creates a 'Text' with the mime type 'application/json'.
	** The json is wrapped in the given callback function name. 
	static new fromJsonP(Str json, Str callbackFuncName, Charset charset := Charset.utf8) {
		text := "${callbackFuncName}(${json});"
		return _fromMimeStr(text, "application/json", charset)
	}

	** Creates a 'Text' with the mime type 'application/json'.
	** The json is wrapped in the given callback function name. 
	** 'jsonObj' should be serialisable into Json via `util::JsonOutStream`.
	static new fromJsonObjP(Obj jsonObj, Str callbackFuncName, Charset charset := Charset.utf8) {
		json := JsonOutStream.writeJsonToStr(jsonObj)
		text := "${callbackFuncName}(${json});"
		return _fromMimeStr(text, "application/json", charset)
	}

	** Creates a 'Text' with the given content type.
	static new fromContentType(Str text, MimeType contentType) {
		Text.make(text, contentType)
	}

	private static new _fromMimeStr(Str text, Str mimeType, Charset charset) {
		Text.make(text, MimeType.fromStr("$mimeType; charset=${charset.name}"))		
	}
	
	override Str toStr() {
		"${contentType.noParams}::${text}"
	}
}
