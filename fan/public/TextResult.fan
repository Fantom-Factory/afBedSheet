
// TODO: take a default Charset charset := Charset.utf8
** Return from Handler methods to send a text response to the client. 
** 
** All `MimeType`s have a charset of 'UTF-8' because that is the default encoding of Fantom Strs.
** 
** This is purposely a concrete final class so there's no ambiguity as to what it is. For example, 
** if a handler returned an Obj that was both a 'TextResult' and a "JsonResult' what is BedSheet 
** supposed to do? 
** 
** Best practice is to have your Entities have a 'toText()' or 'toJson()' method and return that.
** 
** pre>
** Obj myHandler(MyEntity entity) {
**   ...
**   return entity.toJson
** }
** <pre  
const final class TextResult {
	
	const Str 		text
	const MimeType	mimeType
	
	private new make(Str text, MimeType mimeType) {
		this.text = text
		this.mimeType = mimeType
	}
	
	** Creates a 'TextResult' with the `MimeType` 'text/plain; charset=utf-8'
	static TextResult fromPlain(Str text) {
		TextResult(text, MimeType("text/plain; charset=utf-8"))
	}

	** Creates a 'TextResult' with the `MimeType` 'text/html; charset=utf-8'
	static TextResult fromHtml(Str text) {
		TextResult(text, MimeType("text/html; charset=utf-8"))
	}

	** Creates a 'TextResult' with the `MimeType` 'text/xml; charset=utf-8'
	static TextResult fromXml(Str text) {
		TextResult(text, MimeType("text/xml; charset=utf-8"))
	}

	** Creates a 'TextResult' with the `MimeType` 'text/xml; charset=utf-8'
	static TextResult fromMime(Str text, MimeType mimeType) {
		TextResult(text, mimeType)
	}
}
