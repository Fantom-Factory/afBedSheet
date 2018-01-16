using afIoc::Inject
using afIoc::Registry
using afIoc::IocErr
using afConcurrent::LocalRef
using web::WebSession

** (Service) - An injectable 'const' version of [WebSession]`web::WebSession`.
** 
** Provides a name/value map associated with a specific browser *connection* to the web server.
** A cookie (with the name 'fanws') is used to track which session is made available to the request.
** 
** All values stored in the session must be either immutable or serialisable. 
** Note that immutable objects give better performance.  
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
	abstract Bool isEmpty()

	** Returns 'true' if the session map contains the given key. 
	** 
	** Calling this method does not create a session if it does not exist.
	abstract Bool containsKey(Str key)
	
	** Returns session value or def if not defined.
	** 
	** Calling this method does not create a session if it does not exist.
	** 
	** @see `web::WebSession.get`
	@Operator
	abstract Obj? get(Str name, Obj? def := null)

	** Convenience for 'map.getOrAdd(name, valFunc)'.
	** 
	** Calling this **will** create a session if it doesn't already exist.
	abstract Obj? getOrAdd(Str key, |Str->Obj?| valFunc)
	
	** Sets a session value - which must be immutable or serialisable.
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
	
	** A map whose name/value pairs are persisted *only* until the end of the user's **next** HTTP request. 
	** 
	** The returned map is *READ ONLY*. 
	abstract Str:Obj? flash()

	** Sets the given value in the *flash*. 
	** The key/value pair will be persisted until the end of the user's *next* request.
	** 
	** Values must be immutable or serialisable.
	** 
	** Calling this method **will** create a session if it does not exist.
	abstract Void flashSet(Str key, Obj? val)

	** Removes the key/value pair from *flash* and returns the value. 
	** If the key was not mapped then returns 'null'.
	** 
	** Calling this method does not create a session if it does not exist.
	abstract Obj? flashRemove(Str key)
	
	** Adds an event handler that gets called as soon as a session is created.
	** 
	** Callbacks may be mutable, do not need to be cleaned up, but should be added at the start of *every* HTTP request. 
	abstract Void onCreate(|HttpSession| fn)

	internal abstract Void _initFlash()
	internal abstract Void _finalFlash()
	internal abstract Void _finalSession()
}

internal const class HttpSessionImpl : HttpSession {
	private static  const Str:Obj?			emptyRoMap	:= Str:Obj?[:].toImmutable
	@Inject private const |->RequestState|	reqStateFunc
	@Inject	private const LocalRef			reqStateRef
	@Inject	private const HttpCookies		httpCookies
	@Inject	private const LocalRef			existsRef
	
	new make(|This|in) { in(this) } 

	override Str id() {
		session.id
	}

	override Bool isEmpty() {
		if (!exists)
			return true
		
		sessionMap	:= reqState.mutableSessionState
		if (sessionMap.size > 0)
			return false
		
		isEmpty := true
		session.each { isEmpty = false }
		return isEmpty
	}

	override Bool containsKey(Str key) {
		if (!exists)
			return false

		sessionMap	:= reqState.mutableSessionState
		if (sessionMap.containsKey(key))
			return true
		
		containsKey := false
		session.each |v, k| { if (k == key) containsKey = true }
		return containsKey
	}
	
	override Obj? get(Str name, Obj? def := null) {
		if (!exists)
			return def

		sessionMap	:= reqState.mutableSessionState
		if (sessionMap.containsKey(name))
			return sessionMap[name]

		val := session.get(name, def)
		if (val is SessionValue) {
			rawVal := ((SessionValue) val).val
			sessionMap[name] = rawVal
			val = rawVal 
		}
		return val
	}

	override Str:Obj? map() {
		if (!exists) 
			return emptyRoMap

		sessionMap	:= reqState.mutableSessionState
		map			:= reqState.mutableSessionState.dup
		
		session.each |val, key| {
			if (!map.containsKey(key)) {
				if (val is SessionValue) {
					rawVal := ((SessionValue) val).val
					map[key] = rawVal
					sessionMap[key] = rawVal
				} else
					map[key] = val
			}
		} 
		return map.ro
	}

	override Obj? getOrAdd(Str name, |Str->Obj?| valFunc) {
		if (containsKey(name))
			return get(name)
		val := valFunc.call(name)
		set(name, val)
		return val
	}
	
	override Void set(Str name, Obj? val) {
		sessionMap	:= reqState.mutableSessionState
		sessVal		:= SessionValue.coerce(val)
		if (sessVal is SessionValue)
			sessionMap[name] = val
		session.set(name, sessVal)
	}
	
	override Void remove(Str name) {
		if (exists) {
			reqState.mutableSessionState.remove(name)
			session.remove(name)
		}
	}
	
	override Void delete() {
		if (exists) {
			reqState.mutableSessionState.clear
			reqState.mutableSessionState = null
			session.delete
			existsRef.val = false
		}
	}

	override Bool exists() {
		// this gets called a *lot* and each time we manually compile cookie lists just to check if it's empty!
		// so we do a little dirty cashing
		if (existsRef.isMapped)
			return existsRef.val
		
		// make sure the request scope exists so we can further interrogate the session objs 
		try	reqState()
		catch (IocErr ie)
			return false

		// note this session support only for WISP web server
		exists := httpCookies["fanws"] != null
		// note - I could also just check for the existence of 'Actor.locals["web.session"]' 
		// but that's another, more in-depth, wisp implementation detail
		
		if (exists)
			// don't save 'false' values, so we still re-evaluate next time round
			existsRef.val = true
		return exists
	}
	
	override Str:Obj? flash() {
		map := Str:Obj?[:] { it.caseInsensitive = true }
		if (reqState.flashMapOld != null)
			map.setAll(reqState.flashMapOld)
		if (reqState.flashMapNew != null)
			map.setAll(reqState.flashMapNew)
		return map.ro
	}
	
	override Void flashSet(Str key, Obj? val) {
		flashMapNew := reqState.flashMapNew
		
		if (flashMapNew == null)
			reqState.flashMapNew = flashMapNew = Str:Obj?[:]
		flashMapNew[key] = val

		// create a session to preempt setting values
		// FlashMiddleware creates the cookie too late, because the response has already been committed
		session.id
	}

	override Obj? flashRemove(Str key) {
		if (!exists)
			return null
		val	:= null
		if (reqState.flashMapOld != null) {
			if (reqState.flashMapOld.isRO)
				reqState.flashMapOld = reqState.flashMapOld.rw
			val = reqState.flashMapOld.remove(key)
		}
		if (reqState.flashMapNew != null)
			// if the key was found in both maps, it is correct to return the new one
			// as that was the last value to be added, hence the only value in 'flash()'
			val = reqState.flashMapNew.remove(key)
		return val
	}
	
	override Void _initFlash() {
		if (!exists)
			return

		val			:= session.get("afBedSheet.flash")
		carriedOver := val is SessionValue
			? ((SessionValue) val).val
			: val
		reqState.flashMapOld = carriedOver
	}

	override Void _finalFlash() {
		flashMapNew := reqState.flashMapNew

		remove("afBedSheet.flash")
		if (flashMapNew != null && flashMapNew.size > 0)
			session.set("afBedSheet.flash", SessionValue.coerce(flashMapNew))
		
		reqState.flashMapNew = null
	}

	override Void _finalSession() {
		sessionMap	:= reqState.mutableSessionState
		
		sessionMap.each |v, k| { set(k, v) }
		reqState.mutableSessionState.clear
		reqState.mutableSessionState = null
	}
	
	override Void onCreate(|HttpSession| fn) {
		handlers := (|HttpSession|[]) reqState.webReq.stash.getOrAdd("afBedsheet.onHttpSessionCreate") { |HttpSession|[,] }
		handlers.add(fn)
	}
	
	private RequestState reqState() {
		if (reqStateRef.isMapped)
			return reqStateRef.val
		try	return reqStateRef.val = reqStateFunc()
		catch (IocErr ie)
			throw IocErr("Request scope is not available")
	}
	
	** Route all session requests through here so we can trap when it gets created
	private WebSession session() {
		didNotExist := !exists
		session		:= reqState.webReq.session
		
		if (didNotExist) {
			handlers := (|HttpSession|[]) reqState.webReq.stash.getOrAdd("afBedsheet.onHttpSessionCreate") { |HttpSession|[,] }
			handlers.each { it.call(this) }
		}
		return session
	}
}

// Wraps an object value, serialising it if it's not immutable
@NoDoc	// for Bounce
const class SessionValue {
	const Str	objStr
	
	private new make(|This| f) { f(this) }
	
	static Obj? coerce(Obj? val) {
		if (val == null)
			return null
		if (val.isImmutable)
			return val
		
		if (val is Map || val is List || val is Buf || !val.typeof.hasFacet(Serializable#)) {
			try {
				objActual := val.toImmutable
				return objActual
			} catch (NotImmutableErr err) { /* try serialisation */ }
		}

		if (!val.typeof.hasFacet(Serializable#))
			throw BedSheetErr("Session values should be immutable (preferably) or serialisable: ${val.typeof.qname} - ${val}")
		
		// do the serialisation
		return SessionValue {
			it.objStr = Buf().writeObj(val).flip.readAllStr
		}
	}
	
	Obj? val() {
		objStr.toBuf.readObj
	}
	
	override Str toStr() {
		// pretend to be the real object when debugging 
		val?.toStr ?: "null"
	}
}
