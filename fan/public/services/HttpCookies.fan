using afIoc
using web

** (Service) - Use to manage your Cookies.
const mixin HttpCookies {
	
	** Retrieve a cookie by name.
	** Returns 'null' if not found.
	@Operator
	abstract Cookie? get(Str name)

	** Adds a Cookie to be sent to the client. 
	** New cookies are sent via a 'Set-Cookie' HTTP response header.
	**
	** Example:
	**   httpCookies.add(Cookie("foo", "123"))
	**   httpCookies.add(Cookie("persistent", "some val") { maxAge = 3day })
	** 
	** Cookies replace any other cookie with the same name.
	** 
	** Throws Err if response is already committed.
	** @see `web::WebRes.cookies`
	abstract Void add(Cookie cookie)

	** Deletes a cookie by name, returning the deleted cookie. 
	** Returns 'null' if the cookie was not found.
	** 
	** Cookies are deleted from the client by setting the expired attribute to a date in the past.  
	** 
	** Throws Err if response is already committed.
	abstract Cookie? remove(Str cookieName)
	
	** Return a list of all the cookies, including those that have been set but not yet sent to the client.
	abstract Cookie[] all()
}

internal const class HttpCookiesImpl : HttpCookies {
	@Inject	private const HttpRequest	httpReq
	@Inject	private const Registry 		registry
	
	new make(|This|in) { in(this) } 

	override Cookie? get(Str name) {
		all.find { it.name.equalsIgnoreCase(name) }	// ?: (checked ? throw NotFoundErr(BsErrMsgs.cookieNotFound(name), all) : null)
	}

	override Void add(Cookie cookie) {
		existing := webRes.cookies.find { it.name.equalsIgnoreCase(cookie.name) }
		if (existing != null)
			webRes.cookies.removeSame(existing)
		webRes.cookies.add(cookie)
	}

	override Cookie? remove(Str cookieName) {
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
		
		return res	// ?: (checked ? throw NotFoundErr(BsErrMsgs.cookieNotFound(cookieName), all) : null)
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
