using afIoc::Inject
using afIoc::Registry
using web::WebReq

** (Service) - An injectable 'const' version of [WebSession]`web::WebSession`.
** 
** This class is proxied and will always refer to the session in the current web request.
const mixin HttpSession {
	
	** Get the unique id used to identify this session.
	** 
	** Calling this **will** create a session if it doesn't already exist.
	** 
	** @see `web::WebSession`
	abstract Str id()

	** Convenience for 'map.get(name, def)'.
	** 
	** Does not create a session if it does not already exist.
	** 
	** @see `web::WebSession`
	@Operator
	Obj? get(Str name, Obj? def := null) {
		exists ? map.get(name, def) : def 
	}

	** Convenience for 'map.set(name, val)'.
	** 
	** Calling this **will** create a session if it doesn't already exist.
	** 
	** @see `web::WebSession`
	@Operator 
	Void set(Str name, Obj? val) { 
		if (val == null)
			map.remove(name)
		else
			map[name] = val 
	}
	
	** Convenience for 'map.remove(name)'.
	** 
	** Does not create a session if it does not already exist.
	Void remove(Str name) {
		if (exists)
			map.remove(name) 		
	}

	** Application name/value pairs which are persisted between HTTP requests. 
	** The values stored in this map must be serializable.
	** 
	** Calling this **will** create a session if it doesn't already exist.
	** 
	** @see `web::WebSession`
	abstract Str:Obj? map()

	** Delete this web session which clears both the user agent cookie and the server side session 
	** instance. This method must be called before the WebRes is committed otherwise the server side 
	** instance is cleared, but the user agent cookie will remain uncleared.
	** 
	** Does not create a session if it does not already exist.
	** 
	** @see `web::WebSession`
	abstract Void delete()
	
	** Returns 'true' if a session exists. 
	** 
	** Does not create a session if it does not already exist.
	abstract Bool exists()

	** Returns 'true' if the session map is empty. 
	** 
	** Does not create a session if it does not already exist.
	virtual Bool isEmpty() {
		exists ? map.isEmpty : true
	}

	** Returns 'true' if the session map contains the given key. 
	** 
	** Does not create a session if it does not already exist.
	virtual Bool containsKey(Str key) {
		exists ? map.containsKey(key) : false		
	}
}

internal const class HttpSessionImpl : HttpSession {

	@Inject	private const Registry 		registry
	@Inject	private const HttpCookies	httpCookies
	
	new make(|This|in) { in(this) } 

	override Str id() {
		webReq.session.id
	}

	override Str:Obj? map() {
		webReq.session.map
	}

	override Void delete() {
		if (exists)
			webReq.session.delete
	}

	override Bool exists() {
		httpCookies.get("fanws") != null
	}
	
	private WebReq webReq() {
		registry.dependencyByType(WebReq#)
	}
}