
** (Response Object) - 
** Use to send redirect 3xx status codes to the client. Handles the 
** differences in HTTP 1.0 and HTTP 1.1. 
** 
**   syntax: fantom
**   HttpRedirect.movedTemporarily(`/newUrl`)
** 
** @see
**  - `http://en.wikipedia.org/wiki/List_of_HTTP_status_codes#3xx_Redirection`
**  - `http://www.iana.org/assignments/http-status-codes/http-status-codes.xml`
const final class HttpRedirect {
	
	** The URL to redirect to.
	const Uri location

	** Type combined with the HTTP version determines the HTTP status code to return.
	const HttpRedirectType type

	private new make(Uri redirectTo, HttpRedirectType type) {
		this.location	= redirectTo
		this.type		= type
	}

	** Sends a 'Moved Permanently' response to the client with the following status codes:
	**  - 301 for HTTP 1.0 
	**  - 308 for HTTP 1.1
	** 
	** The client should use the same HTTP method when requesting the redirect.
	static new movedPermanently(Uri redirectTo) {
		// @see http://fantom.org/sidewalk/topic/2169#c14003
		// @see http://fantom.org/forum/topic/2683#c1
		HttpRedirect.make(redirectTo, HttpRedirectType.movedPermanently)
	}

	** Sends a 'Moved Temporarily' response to the client with the following status codes:
	**  - 302 for HTTP 1.0 
	**  - 307 for HTTP 1.1
	** 
	** The client should use the same HTTP method when requesting the redirect.
	static new movedTemporarily(Uri redirectTo) {
		HttpRedirect.make(redirectTo, HttpRedirectType.movedTemporarily)
	}

	** Use when the client should perform a HTTP GET to the returned location. Typically this is 
	** when you implement the *Redirect After Post* paradigm. 
	**  - 302 for HTTP 1.0 
	**  - 303 for HTTP 1.1
	static new afterPost(Uri redirectTo) {
		HttpRedirect.make(redirectTo, HttpRedirectType.afterPost)
	}
	
	** Throw to send a redirect to the client. 
	** Use in exceptional cases where it may not be suitable / possible to return a 'Redirect' instance.
	** 
	**   syntax: fantom
	**   throw HttpRedirect.movedPermanentlyErr(`/some/other/page.html`)
	static ReProcessErr movedPermanentlyErr(Uri redirectTo) {
		ReProcessErr(HttpRedirect.movedPermanently(redirectTo))
	}

	** Throw to send a redirect to the client. 
	** Use in exceptional cases where it may not be suitable / possible to return a 'Redirect' instance.
	** 
	**   syntax: fantom
	**   throw HttpRedirect.movedTemporarilyErr(`/some/other/page.html`)
	static ReProcessErr movedTemporarilyErr(Uri redirectTo) {
		ReProcessErr(HttpRedirect.movedTemporarily(redirectTo))
	}

	** Throw to send a redirect to the client. 
	** Use in exceptional cases where it may not be suitable / possible to return a 'Redirect' instance.
	** 
	**   syntax: fantom
	**   throw HttpRedirect.afterPostErr(`/some/other/page.html`)
	static ReProcessErr afterPostErr(Uri redirectTo) {
		ReProcessErr(HttpRedirect.afterPost(redirectTo))
	}
	
	@NoDoc
	override Str toStr() {
		"Redirect -> ${location} (${type.toStr.toDisplayName})"
	}
	
	internal static HttpRedirect fromLegacy(Redirect redirect) {
		HttpRedirect(redirect.location, redirect.type)
	}
}

** (Response Object) - 
** Use to send redirect 3xx status codes to the client. Handles the 
** differences in HTTP 1.0 and HTTP 1.1. 
** 
**   syntax: fantom
**   HttpRedirect.movedTemporarily(`/newUrl`)
** 
** @see
**  - `http://en.wikipedia.org/wiki/List_of_HTTP_status_codes#3xx_Redirection`
**  - `http://www.iana.org/assignments/http-status-codes/http-status-codes.xml`
@NoDoc @Deprecated { msg="Use HttpRedirect instead" }
const final class Redirect {
	
	@NoDoc @Deprecated { msg="Use 'location' instead" }
	Uri uri() { location }

	** The URL to redirect to.
	const Uri location

	** Type combined with the HTTP version determines the HTTP status code to return.
	const HttpRedirectType type

	private new make(Uri redirectTo, HttpRedirectType type) {
		this.location	= redirectTo
		this.type		= type
	}

	** Sends a 'Moved Permanently' response to the client with the following status codes:
	**  - 301 for HTTP 1.0 
	**  - 308 for HTTP 1.1
	** 
	** The client should use the same HTTP method when requesting the redirect.
	static new movedPermanently(Uri redirectTo) {
		// @see http://fantom.org/sidewalk/topic/2169#c14003
		// @see http://fantom.org/forum/topic/2683#c1
		Redirect.make(redirectTo, HttpRedirectType.movedPermanently)
	}

	** Sends a 'Moved Temporarily' response to the client with the following status codes:
	**  - 302 for HTTP 1.0 
	**  - 307 for HTTP 1.1
	** 
	** The client should use the same HTTP method when requesting the redirect.
	static new movedTemporarily(Uri redirectTo) {
		Redirect.make(redirectTo, HttpRedirectType.movedTemporarily)
	}

	** Use when the client should perform a HTTP GET to the returned location. Typically this is 
	** when you implement the *Redirect After Post* paradigm. 
	**  - 302 for HTTP 1.0 
	**  - 303 for HTTP 1.1
	static new afterPost(Uri redirectTo) {
		Redirect.make(redirectTo, HttpRedirectType.afterPost)
	}
	
	** Throw to send a redirect to the client. 
	** Use in exceptional cases where it may not be suitable / possible to return a 'Redirect' instance.
	** 
	**   syntax: fantom
	**   throw HttpRedirect.movedPermanentlyErr(`/some/other/page.html`)
	static ReProcessErr movedPermanentlyErr(Uri redirectTo) {
		ReProcessErr(HttpRedirect.movedPermanently(redirectTo))
	}

	** Throw to send a redirect to the client. 
	** Use in exceptional cases where it may not be suitable / possible to return a 'Redirect' instance.
	** 
	**   syntax: fantom
	**   throw HttpRedirect.movedTemporarilyErr(`/some/other/page.html`)
	static ReProcessErr movedTemporarilyErr(Uri redirectTo) {
		ReProcessErr(HttpRedirect.movedTemporarily(redirectTo))
	}

	** Throw to send a redirect to the client. 
	** Use in exceptional cases where it may not be suitable / possible to return a 'Redirect' instance.
	** 
	**   syntax: fantom
	**   throw HttpRedirect.afterPostErr(`/some/other/page.html`)
	static ReProcessErr afterPostErr(Uri redirectTo) {
		ReProcessErr(HttpRedirect.afterPost(redirectTo))
	}
	
	@NoDoc
	override Str toStr() {
		"Redirect -> ${location} (${type.toStr.toDisplayName})"
	}
}

** The type of HttpRedirect.
enum class HttpRedirectType {
	// order is important - see statusCode() below
	movedPermanently,
	movedTemporarily,
	afterPost;
	
	private static const Version ver10 		:= Version("1.0")
	private static const Int[] statusCodes	:= [301, 302, 302, 308, 307, 303]

	** Returns the HTTP status code associated with this redirect type, based on the given HTTP version.
	** If the no HTTP version is given, it is assumed to be HTTP 1.1.
	** 
	** Note status codes only differ for HTTP 1.0.
	Int statusCode(Version? httpVer := null) {
		index := ordinal
		if (httpVer == null || httpVer > ver10)
			index = index + 3
		return statusCodes[index]
	}
}
