using afIoc3::Inject
using afIoc3::Registry
using concurrent::Actor

** (Service) - An injectable 'const' version of [WebSession]`web::WebSession`.
** 
** Provides a name/value map associated with a specific browser *connection* to the web server.
** A cookie (with the name 'fanws') is used to track which session is made available to the request.
** 
** All values stored in the session must be immutable.
** 
** For scalable applications, the session should be used sparingly; house cleaned regularly and not used as a dumping ground. 
** 
** Flash 
** -----
** Whereas normal session values are persisted indefinitely, flash vales only exist until the end of the next request.
** After that, they are removed from the session.
** 
** A common usage is to store message values before a redirect (usually after a form post).
** When the following page is rendered, the message is retrieved and displayed.
** After which the message is automatically discarded from the session. 
** 
** *(Flash: A-ah - Saviour of the Universe!)*  
const mixin HttpSession {
	
	** Get the unique id used to identify this session.
	** 
	** Calling this method **will** create a session if it does not exist.
	** 
	** @see `web::WebSession.id`
	abstract Str id()

	** Returns 'true' if the session map is empty. 
	** 
	** Calling this method does not create a session if it does not exist.
	virtual Bool isEmpty() {
		exists ? map.isEmpty : true
	}

	** Returns 'true' if the session map contains the given key. 
	** 
	** Calling this method does not create a session if it does not exist.
	virtual Bool containsKey(Str key) {
		exists ? map.containsKey(key) : false		
	}
	
	** Returns session value or def if not defined.
	** 
	** Calling this method does not create a session if it does not exist.
	** 
	** @see `web::WebSession.get`
	@Operator
	virtual Obj? get(Str name, Obj? def := null) {
		exists ? map.get(name, def) : def 
	}

	** Convenience for 'map.getOrAdd(name, valFunc)'.
	** 
	** Calling this **will** create a session if it doesn't already exist.
	abstract Obj? getOrAdd(Str key, |Str->Obj?| valFunc)
	
	** Sets a session value - which must be immutable.
	** 
	** Calling this method **will** create a session if it does not exist.
	** 
	** @see `web::WebSession.set`
	@Operator 
	abstract Void set(Str name, Obj? val)
	
	** Convenience for 'map.remove(name)'.
	** 
	** Calling this method does not create a session if it does not exist.
	** 
	** @see `web::WebSession.remove`
	abstract Void remove(Str name)

	** The application name/value pairs which are persisted between HTTP requests. 
	** Returns an empty map if a session does not exist.
	** 
	** Calling this method does not create a session if it does not exist.
	** 
	** The returned map is *READ ONLY*. 
	abstract Str:Obj? map()

	** Delete this web session which clears both the user agent cookie and the server side session 
	** instance. This method must be called before the WebRes is committed otherwise the server side 
	** instance is cleared, but the user agent cookie will remain uncleared.
	** 
	** Calling this method does not create a session if it does not exist.
	** 
	** @see `web::WebSession.delete`
	abstract Void delete()
	
	** Returns 'true' if a session exists. 
	** 
	** Calling this method does not create a session if it does not exist.
	abstract Bool exists()
	
	** A map whose name/value pairs are persisted *only* until the end of the user's next HTTP request. 
	** Values stored in this map must be immutable.
	** 
	** The returned map is *MODIFIABLE*. 
	** 
	** Calling this method **will** create a session if it does not exist. 
	** Use 'flashExists()' to check if a value exists without creating a session:
	** 
	**   if (httpSession.flashExists && httpSession.flash.contains("key")) { ... }
	abstract Str:Obj? flash()
	
	** Returns 'true' if the flash map exists.
	** 
	** Calling this method does not create a session if it does not exist.
	abstract Bool flashExists()
	
	internal abstract Void _initFlash()
	internal abstract Void _finalFlash()
}

internal const class HttpSessionImpl : HttpSession {
	private static  const Str:Obj?			emptyRoMap	:= Str:Obj?[:].toImmutable
	@Inject private const |->RequestState|	reqState
	@Inject	private const HttpCookies		httpCookies
	
	new make(|This|in) { in(this) } 

	override Str id() {
		reqState().webReq.session.id
	}

	override Str:Obj? map() {
		if (!exists) 
			return emptyRoMap
		
		map := Str:Obj?[:]
		reqState().webReq.session.each |val, key| {
			map[key] = val
		} 
		return map
	}

	override Obj? getOrAdd(Str name, |Str->Obj?| valFunc) {
		map := map
		if (map.containsKey(name))
			return map[name]
		
		val := valFunc.call(name)
		set(name, val)
		return val
	}
	
	override Void set(Str name, Obj? val) { 
		reqState().webReq.session.set(name, testImmutable(val))
	}
	
	override Void remove(Str name) {
		if (exists)
			reqState().webReq.session.remove(name)
	}
	
	override Void delete() {
		if (exists) {
			map := map
			map.keys.each { reqState().webReq.session.remove(it) }
			reqState().webReq.session.delete
		}
	}

	override Bool exists() {
		// TODO: this session support only for WISP web server
		Actor.locals["web.req"] != null && httpCookies.get("fanws") != null
	}
	
	override Str:Obj? flash() {
		// need to preempt setting values
		// FlashMiddleware happens too late 'cos the response has already been committed (usually) 
		// when we try to create the cookie  
		reqState().webReq.session.id
		return reqState().flashMapNew
	}

	override Bool flashExists() {
		exists && containsKey("afBedSheet.flash")
	}
	
	override Void _initFlash() {
		reqState	:= (RequestState) reqState()
		carriedOver := get("afBedSheet.flash")
		reqState.flashMapOld = carriedOver ?: emptyRoMap
		reqState.flashMapNew = reqState.flashMapOld.rw
	}

	override Void _finalFlash() {
		reqState	:= reqState()
		flashMapOld := reqState.flashMapOld
		flashMapNew := reqState.flashMapNew

		// TODO: replace flash map with a pseudo map so we can capture the get and set operations.
		// - benefits are, we can capture the set() method to make note of re-setting keys 

		// remove old key / values that have not changed
		// note - this means we can not re-set the same value!
		flashMapOld.each |oldVal, oldKey| {
			if (flashMapNew.containsKey(oldKey) && flashMapNew[oldKey] == oldVal)
				flashMapNew.remove(oldKey)
		}

		// test serialisation - would rather do this sooner if we could
		flashMapNew.each {
			testImmutable(it)
		}
		
		if (flashMapNew.isEmpty)
			remove("afBedSheet.flash")
		else
			set("afBedSheet.flash", flashMapNew)
	}
	
	private Obj? testImmutable(Obj? val) {
		val?.toImmutable
	}
}