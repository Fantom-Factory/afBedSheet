using afIoc::Inject
using afIoc::Registry
using web::WebReq

** An injectable 'const' version of [WebSession]`web::WebSession`.
** 
** This class is proxied and will always refer to the session in the current web request.
const mixin HttpSession {
	
	** Get the unique id used to identify this session.
	** Calling this will create a session if it doesn't already exist.
	** 
	** @see `web::WebSession`
	abstract Str id()

	** Convenience for 'map.get(name, def)'.
	** 
	** @see `web::WebSession`
	@Operator
	Obj? get(Str name, Obj? def := null) { map.get(name, def) }

	** Convenience for 'map.set(name, val)'.
	** 
	** @see `web::WebSession`
	@Operator 
	Void set(Str name, Obj? val) { 
		if (val == null)
			map.remove(name)
		else
			map[name] = val 
	}

	** Application name/value pairs which are persisted between HTTP requests. 
	** The values stored in this map must be serializable.
	** 
	** @see `web::WebSession`
	abstract Str:Obj? map()

	** Delete this web session which clears both the user agent cookie and the server side session 
	** instance. This method must be called before the WebRes is committed otherwise the server side 
	** instance is cleared, but the user agent cookie will remain uncleared.
	** 
	** @see `web::WebSession`
	abstract Void delete()
	
	** Returns 'true' if a session exists. 
	abstract Bool exists()

	** Returns 'true' if the session map is empty. 
	abstract Bool isEmpty()
}

internal const class HttpSessionImpl : HttpSession {

	@Inject
	private const Registry registry
	
	new make(|This|in) { in(this) } 

	override Str id() {
		webReq.session.id
	}

	override Str:Obj? map() {
		webReq.session.map
	}

	override Void delete() {
		webReq.session.delete
	}

	override Bool exists() {		
		HttpRequest req := registry.dependencyByType(HttpRequest#)
		if (req.cookies.containsKey("fanws"))
			return true

		HttpResponse res := registry.dependencyByType(HttpResponse#)
		if (!res.isCommitted && res.cookies.any |cookie| { cookie.name == "fanws" })
			return true
		
		return false
	}
	
	override Bool isEmpty() {
		webReq.session.map.isEmpty
	}

	private WebReq webReq() {
		registry.dependencyByType(WebReq#)
	}
}