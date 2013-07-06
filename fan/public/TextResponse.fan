using util::JsonOutStream

// TODO: TextResponse to take a default Charset charset := Charset.utf8
** Return from Handler methods to send a text response to the client. 
** 
** All `MimeType`s have a charset of 'UTF-8' because that is the default encoding of Fantom Strs.
** 
** This is purposely a concrete final class so there is no ambiguity as to what it is. For example, 
** if a handler returned an Obj that was both a 'TextResponse' and a "JsonResponse' what is BedSheet 
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
const final class TextResponse {
	
	const Str 		text
	const MimeType	mimeType
	
	private new make(Str text, MimeType mimeType) {
		this.text = text
		this.mimeType = mimeType
	}

	** Creates a 'TextResponse' with the `MimeType` 'text/plain'.
	static new fromPlain(Str text) {
		TextResponse.make(text, MimeType("text/plain; charset=$Charset.utf8.name"))
	}

	** Creates a 'TextResponse' with the `MimeType` 'text/html'.
	static new fromHtml(Str text) {
		TextResponse.make(text, MimeType("text/html; charset=$Charset.utf8.name"))
	}

	** Creates a 'TextResponse' with the `MimeType` 'text/xml'.
	static new fromXml(Str text) {
		TextResponse.make(text, MimeType("text/xml; charset=$Charset.utf8.name"))
	}

	** Creates a 'TextResponse' with the `MimeType` 'application/json'.
	** 'jsonObj' should be serialisable into Json via `util::JsonOutStream`
	static new fromJson(Obj jsonObj) {
		json := JsonOutStream.writeJsonToStr(jsonObj)
		return TextResponse.make(json, MimeType("application/json; charset=$Charset.utf8.name"))		
	}
	
	** Creates a 'TextResponse' with the `MimeType` 'application/json'.
	** The json is wrapped in the given callback function name. 
	** 'jsonObj' should be serialisable into Json via `util::JsonOutStream`.
	static new fromJsonP(Obj jsonObj, Str callbackFuncName) {
		json := JsonOutStream.writeJsonToStr(jsonObj)
		text := "${callbackFuncName}(${json});" 
		return TextResponse.make(text, MimeType("application/json; charset=$Charset.utf8.name"))
	}
	
	** Creates a 'TextResponse' with the given `MimeType`.
	static new fromMimeType(Str text, MimeType mimeType) {
		TextResponse.make(text, mimeType)
	}
}
