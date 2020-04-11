
class Route2 {
    Obj		handler
	Uri		requestUrl
    Uri		canonicalUrl
    Str[]	wildcardSegments
    Str[]	remainingSegments

	new make(Uri requestUrl, Uri canonicalUrl, Obj handler, Str[] wildcardSegments, Str[] remainingSegments) {
		this.requestUrl = requestUrl
		this.canonicalUrl = canonicalUrl
		this.handler = handler
		this.wildcardSegments = wildcardSegments
		this.remainingSegments = remainingSegments
	}
}

internal class Route3 {
    Obj		handler
	Str[]	canonical
    Str[]	wildcards
    Str[]	remaining

	new make(Obj handler) {
		this.handler	= handler
		this.canonical	= Str[,]
		this.wildcards	= Str[,]
		this.remaining	= Str[,]
	}

	Uri canonicalUrl() {
		url := ``
		for (i := 0; i < canonical.size; ++i) {
			url = url.plusSlash.plusName(canonical[i])
		}
		return url
	}
}