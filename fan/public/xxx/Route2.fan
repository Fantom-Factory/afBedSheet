
class Route2 {
	Uri    requestUrl
	// --> what's this?
    Uri    definedUrl
    Uri?   canonicalUrl
    Obj    handler

    // --> my bad, these need to be different
    // --> so this is JUST the wildcards
    Str[]  wildcardSegments

    // --> and this is JUST the remaining segs
    Str[]  remainingSegments

	new make(Uri requestUrl, Uri definedUrl, Uri? canonicalUrl, Obj handler, Str[] wildcardSegments, Str[] remainingSegments) {
		this.requestUrl = requestUrl
		this.definedUrl = definedUrl
		this.canonicalUrl = canonicalUrl
		this.handler = handler
		this.wildcardSegments = wildcardSegments
		this.remainingSegments = remainingSegments
	}
}