
** (Response Object) - 
** Use to send redirect 3xx status codes to the client. Handles the 
** differences in HTTP 1.0 and HTTP 1.1. 
** 
**   syntax: fantom
**   Redirect.movedTemporarily(`/newUrl`)
** 
** @see
**  - `http://en.wikipedia.org/wiki/List_of_HTTP_status_codes#3xx_Redirection`
**  - `http://www.iana.org/assignments/http-status-codes/http-status-codes.xml`
const final class Redirect {
	
	** The URI to redirect to
	const Uri uri

	internal const RedirectType type

	private new make(Uri redirectTo, RedirectType type) {
		this.uri = redirectTo
		this.type = type
	}

	** Sends a 'Moved Permanently' response to the client with the following status codes:
	**  - 301 for HTTP 1.0 
	**  - 308 for HTTP 1.1
	** 
	** The client should use the same HTTP method when requesting the redirect.
	// @see `http://fantom.org/sidewalk/topic/2169#c14003`
	static new movedPermanently(Uri redirectTo) {
		Redirect.make(redirectTo, RedirectType.movedPermanently)
	}

	** Sends a 'Moved Temporarily' response to the client with the following status codes:
	**  - 302 for HTTP 1.0 
	**  - 307 for HTTP 1.1
	** 
	** The client should use the same HTTP method when requesting the redirect.
	static new movedTemporarily(Uri redirectTo) {
		Redirect.make(redirectTo, RedirectType.movedTemporarily)
	}

	** Use when the client should perform a HTTP GET on the returned uri. Typically this is 
	** when you implement the *Redirect After Post* paradigm. 
	**  - 302 for HTTP 1.0 
	**  - 303 for HTTP 1.1
	static new afterPost(Uri redirectTo) {
		Redirect.make(redirectTo, RedirectType.afterPost)
	}
	
	** Throw to send a redirect to the client. 
	** Use in exceptional cases where it may not be suitable / possible to return a 'Redirect' instance.
	** 
	**   syntax: fantom
	**   throw Redirect.movedPermanentlyErr(`/some/other/page.html`)
	static ReProcessErr movedPermanentlyErr(Uri redirectTo) {
		ReProcessErr(Redirect.movedPermanently(redirectTo))
	}

	** Throw to send a redirect to the client. 
	** Use in exceptional cases where it may not be suitable / possible to return a 'Redirect' instance.
	** 
	**   syntax: fantom
	**   throw Redirect.movedTemporarilyErr(`/some/other/page.html`)
	static ReProcessErr movedTemporarilyErr(Uri redirectTo) {
		ReProcessErr(Redirect.movedTemporarily(redirectTo))
	}

	** Throw to send a redirect to the client. 
	** Use in exceptional cases where it may not be suitable / possible to return a 'Redirect' instance.
	** 
	**   syntax: fantom
	**   throw Redirect.afterPostErr(`/some/other/page.html`)
	static ReProcessErr afterPostErr(Uri redirectTo) {
		ReProcessErr(Redirect.afterPost(redirectTo))
	}
	
	@NoDoc
	override Str toStr() {
		"Redirect -> ${uri} (${type.toStr.toDisplayName})"
	}
}

** the order is important - see `RedirectResponseProcessor`
internal enum class RedirectType {
	movedPermanently,
	movedTemporarily,
	afterPost;
}