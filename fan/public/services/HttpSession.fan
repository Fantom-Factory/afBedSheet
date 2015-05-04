using afIoc::Inject
using afIoc::Registry
using web::WebReq

** (Service) - An injectable 'const' version of [WebSession]`web::WebSession`.
** 
** Provides a name/value map associated with a specific browser *connection* to the web server.
** A cookie (with the name 'fanws') is used to track which session is made available to the request.
** 
** All values stored in the session must be serializable.
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
	** @see `web::WebSession`
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
	
	** Convenience for 'map.get(name, def)'.
	** 
	** Calling this method does not create a session if it does not exist.
	** 
	** @see `web::WebSession`
	@Operator
	virtual Obj? get(Str name, Obj? def := null) {
		exists ? map.get(name, def) : def 
	}

	** Convenience for 'map.getOrAdd(name, valFunc)'.
	** 
	** Calling this **will** create a session if it doesn't already exist.
	abstract Obj? getOrAdd(Str key, |Str->Obj?| valFunc)
	
	** Convenience for 'map.set(name, val)'.
	** 
	** Calling this method **will** create a session if it does not exist.
	** 
	** @see `web::WebSession`
	@Operator 
	abstract Void set(Str name, Obj? val)
	
	** Convenience for 'map.remove(name)'.
	** 
	** Calling this method does not create a session if it does not exist.
	abstract Void remove(Str name)

	** Application name/value pairs which are persisted between HTTP requests. 
	** The values stored in this map must be serializable.
	** 
	** Calling this method **will** create a session if it does not exist.
	** 
	** The returned map is *READ ONLY*. 
	** Use the methods on this class to write to the session.
	** This is so we can *fail fast* (before a response is sent to the user) should a value not be serializable.
	** 
	** @see `web::WebSession`
	abstract Str:Obj? map()

	** Delete this web session which clears both the user agent cookie and the server side session 
	** instance. This method must be called before the WebRes is committed otherwise the server side 
	** instance is cleared, but the user agent cookie will remain uncleared.
	** 
	** Calling this method does not create a session if it does not exist.
	** 
	** @see `web::WebSession`
	abstract Void delete()
	
	** Returns 'true' if a session exists. 
	** 
	** Calling this method does not create a session if it does not exist.
	abstract Bool exists()
	
	** A map whose name/value pairs are persisted *only* until the end of the user's next HTTP request. 
	** Values stored in this map must be serializable.
	** 
	** The returned map is *MODIFIABLE*. 
	** 
	** Calling this method **will** create a session if it does not exist. 
	** Use 'flashExists()' to check if a value exists without creating a session:
	** 
	**   if (httpSession.flashExists && httpSession.flash.contains("key")) { ... }
	** 
	** @see `web::WebSession`
	abstract Str:Obj? flash()
	
	** Returns 'true' if the flash map exists.
	** 
	** Calling this method does not create a session if it does not exist.
	abstract Bool flashExists()
}

internal const class HttpSessionImpl : HttpSession {

	@Inject	private const Registry 		registry
	@Inject	private const HttpCookies	httpCookies
	
	new make(|This|in) { in(this) } 

	override Str id() {
		webReq.session.id
	}

	override Str:Obj? map() {
		mapRw.ro
	}

	override Obj? getOrAdd(Str key, |Str->Obj?| valFunc) {
		if (!mapRw.containsKey(key)) {
			val := valFunc.call(key)
			mapRw[key] = testSerialisation(val)
		}
		return mapRw[key]
	}
	
	override Void set(Str name, Obj? val) { 
		mapRw[name] = testSerialisation(val)
	}
	
	override Void remove(Str name) {
		if (exists)
			mapRw.remove(name) 		
	}
	
	override Void delete() {
		if (exists) {
			mapRw.clear
			webReq.session.delete
		}
	}

	override Bool exists() {
		// session support only for WISP web server
		httpCookies.get("fanws") != null
	}
	
	// TODO: replace flash map with a pseudo map so we can capture the get and set operations.
	// - benefits are, we don't create a session on read and split map up into a req and res 
	override Str:Obj? flash() {
		getOrAdd("afBedSheet.flash") { Str:Obj?[:] }
	}

	override Bool flashExists() {
		exists && containsKey("afBedSheet.flash")
	}
	
	private Obj? testSerialisation(Obj? val) {
		Buf().out.writeObj(val, ["skipErrors":false])
		return val
	}
	
	private Str:Obj? mapRw() {
		webReq.session.map
	}
	
	private WebReq webReq() {
		registry.dependencyByType(WebReq#)
	}
}