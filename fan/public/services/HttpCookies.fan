using afIoc::Inject
using web::Cookie
using concurrent

** (Service) - Use to manage your Cookies.
const mixin HttpCookies {

	** Adds a Cookie to be sent to the client. 
	** New cookies are sent via a 'Set-Cookie' HTTP response header.
	**
	** Example:
	**   syntax: fantom
	**   httpCookies.add(Cookie("foo", "123"))
	**   httpCookies.add(Cookie("persistent", "some val") { maxAge = 3day })
	** 
	** Cookies replace any other cookie with the same name.
	** 
	** Throws Err if response is already committed.
	** @see `web::WebRes.cookies`
	abstract Void add(Cookie cookie)
	
	** Retrieve a cookie by name.
	** Returns 'null' if not found.
	@Operator
	abstract Cookie? get(Str name)

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
	@Inject	private const HttpRequest		httpReq
	@Inject private const |->RequestState|	reqStateFunc
	
	new make(|This|in) { in(this) } 

	override Cookie? get(Str name) {
		all.find { it.name.equalsIgnoreCase(name) }	// ?: (checked ? throw NotFoundErr(BsErrMsgs.cookieNotFound(name), all) : null)
	}

	override Void add(Cookie cookie) {
		cookies := reqState.webRes.cookies
		existing := cookies.find { it.name.equalsIgnoreCase(cookie.name) }
		if (existing != null)
			cookies.removeSame(existing)
		cookies.add(cookie)
	}

	override Cookie? remove(Str cookieName) {
		cookies := reqState.webRes.cookies
		res := cookies.find { it.name.equalsIgnoreCase(cookieName) }
		if (res != null)
			cookies.removeSame(res)
		
		// don't return res straight away as it may also be set in the req
		req := httpReq.headers.cookies?.find { it.name.equalsIgnoreCase(cookieName) }
		if (req != null) {
			dieCookie := Cookie(cookieName, "deleted-by-BedSheet") { it.maxAge = 0sec }
			cookies.add(dieCookie)
			return req
		}
		
		return res	// ?: (checked ? throw NotFoundErr(BsErrMsgs.cookieNotFound(cookieName), all) : null)
	}
	
	override Cookie[] all() {
		cookies := httpReq.headers.cookies ?: Cookie[,]
		if (!reqState.webRes.isCommitted)
			cookies.addAll(reqState.webRes.cookies)
		return cookies
	}
	
	private RequestState reqState() {
		reqStateFunc()
	}
}
