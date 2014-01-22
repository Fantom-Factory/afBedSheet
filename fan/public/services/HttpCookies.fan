using afIoc
using web

const mixin HttpCookies {
	
	@Operator
	abstract Cookie? get(Str name, Bool checked := true)

	abstract Void set(Cookie cookie)

	abstract Cookie? remove(Str cookieName, Bool checked := true)
	
	abstract Cookie[] all()
	
}

internal const class HttpCookiesImpl : HttpCookies {
	@Inject	private const HttpRequest	httpReq
	@Inject	private const Registry 		registry
	
	new make(|This|in) { in(this) } 

	override Cookie? get(Str name, Bool checked := true) {
		all.find { it.name.equalsIgnoreCase(name) } ?: (checked ? throw NotFoundErr(BsErrMsgs.cookieNotFound(name), all) : null)
	}

	override Void set(Cookie cookie) {
		existing := webRes.cookies.find { it.name.equalsIgnoreCase(cookie.name) }
		if (existing != null)
			webRes.cookies.removeSame(existing)
		webRes.cookies.add(cookie)
	}

	override Cookie? remove(Str cookieName, Bool checked := true) {
		res := webRes.cookies.find { it.name.equalsIgnoreCase(cookieName) }
		if (res != null)
			webRes.cookies.removeSame(res)
		
		// don't return res straight away as it may also be set in the req
		req := httpReq.headers.cookies.find { it.name.equalsIgnoreCase(cookieName) }
		if (req != null) {
			dieCookie := Cookie(cookieName, "deleted-by-BedSheet") { it.maxAge = 0sec }
			webRes.cookies.add(dieCookie)
			return req
		}
		
		return res ?: (checked ? throw NotFoundErr(BsErrMsgs.cookieNotFound(cookieName), all) : null)
	}
	
	override Cookie[] all() {
		cookies := httpReq.headers.cookies ?: Cookie[,]
		if (!webRes.isCommitted)
			cookies.addAll(webRes.cookies)
		return cookies
	}
	
	private WebRes webRes() {
		registry.dependencyByType(WebRes#)
	}
}