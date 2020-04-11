
class Route2 {
	Uri    requestUrl
	
    Uri?   canonicalUrl
	
    Obj    handler

    // --> my bad, these need to be different
    // --> so this is JUST the wildcards
    Str[]  wildcardSegments

    // --> and this is JUST the remaining segs
    Str[]  remainingSegments

	new make(Uri requestUrl, Uri foo, Uri? canonicalUrl, Obj handler, Str[] wildcardSegments, Str[] remainingSegments) {
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

	new make(Obj handler, Str canonical) {
		this.handler	= handler
		this.canonical	= Str[canonical]
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