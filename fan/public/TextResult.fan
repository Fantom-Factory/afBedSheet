
** All `MimeType`s have a charset of 'UTF-8' because that the default encoding of Fantom Strs. 
const class TextResult {
	
	const Str 		text
	const MimeType	mimeType
	
	private new make(Str text, MimeType mimeType) {
		this.text = text
		this.mimeType = mimeType
	}
	
	** Creates a 'TextResult' with the `MimeType` 'text/plain; charset=utf-8'
	TextResult fromPlain(Str text) {
		TextResult(text, MimeType("text/plain; charset=utf-8"))
	}

	** Creates a 'TextResult' with the `MimeType` 'text/html; charset=utf-8'
	TextResult fromHtml(Str text) {
		TextResult(text, MimeType("text/html; charset=utf-8"))
	}

	** Creates a 'TextResult' with the `MimeType` 'text/xml; charset=utf-8'
	TextResult fromXml(Str text) {
		TextResult(text, MimeType("text/xml; charset=utf-8"))
	}

	** Creates a 'TextResult' with the `MimeType` 'text/xml; charset=utf-8'
	TextResult fromMime(Str text, MimeType mimeType) {
		TextResult(text, mimeType)
	}
}
