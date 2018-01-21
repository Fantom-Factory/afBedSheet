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
	abstract Obj? remove(Str name)

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
	** (Note that actually they're persisted until the next request in which 'flash()' is called again.)
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
			rawVal := SessionValue.deserialise(val)
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
					rawVal := SessionValue.deserialise(val)
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
		// attempt serialisation just so we can fail fast and grab the users attention
		sessVal		:= SessionValue.serialise(val)
		if (isMutable(val))
			// let mutable maps and lists stay mutable until the end of the request
			reqState.mutableSessionState[name] = val
		else
			reqState.mutableSessionState.remove(name)
		// always create the session on demand - when we expect it to (and before the response is committed)
		session.set(name, sessVal)
	}
	
	override Obj? remove(Str name) {
		if (exists) {
			val1 := reqState.mutableSessionState.remove(name)
			val2 := session.get(name) 
			session.remove(name)	// session.remove returns Void - see http://fantom.org/forum/topic/2672
			return val1 ?: val2
		}
		return null
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
		_initFlash
		
		oldFlashMap := reqState.flashOldMap
		newFlashMap := get("afBedSheet.flash")

		map := Str:Obj?[:] { it.caseInsensitive = true }
		if (oldFlashMap != null)
			map.setAll(oldFlashMap)
		if (newFlashMap != null)
			map.setAll(newFlashMap)

		return map.ro
	}
	
	override Void flashSet(Str key, Obj? val) {
		_initFlash
		newFlashMap := ([Str:Obj?]?) get("afBedSheet.flash")
		if (newFlashMap == null) {
			newFlashMap = Str:Obj?[:]
			set("afBedSheet.flash", newFlashMap)
		}
		newFlashMap[key] = val
	}

	override Obj? flashRemove(Str key) {
		_initFlash
		
		oldFlashMap := reqState.flashOldMap
		newFlashMap := ([Str:Obj?]?) get("afBedSheet.flash")

		val1 := null
		if (oldFlashMap != null)
			val1 = oldFlashMap.remove(key)

		val2 := null
		if (newFlashMap != null)
			val2 = newFlashMap.remove(key)
		
		return val2 ?: val1
	}

	override Void _finalSession() {
		sessionMap := reqState.mutableSessionState
		if (sessionMap != null && sessionMap.size > 0) {
			session := session
			sessionMap.each |v, k| {
				session[k] = SessionValue.serialise(v)
			}
			sessionMap.clear
		}
		reqState.mutableSessionState = null
	}
	
	override Void onCreate(|HttpSession| fn) {
		reqState.addSessionCreateFn(fn)
	}
	
	// if this is called *every* request (as it was in BedSheet 1.5.8) then 
	// the Session is loaded (from database?) on *every* request, including for the many asset requests
	// getting the user to call 'flash()' when they want to clear it is a happy compromise
	private Void _initFlash() {
		if (reqState.flashInitialised) return

		// grab the old value...
		reqState.flashOldMap = get("afBedSheet.flash")

		// ... and delete it
		remove("afBedSheet.flash")
		
		reqState.flashInitialised = true
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
		if (didNotExist)
			reqState.fireSessionCreate(this)
		return session
	}

	private static Bool isMutable(Obj? val) {
		val != null && !val.isImmutable
	}
}

// Wraps an object value, serialising it if it's not immutable
@NoDoc	// for Bounce
const class SessionValue {
	const Str	objStr
	
	private new make(|This| f) { f(this) }
	
	static Obj? serialise(Obj? val) {
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
	
	static Obj? deserialise(Obj? val) {
		val is SessionValue ? ((SessionValue) val).val : val
	}
	
	Obj? val() {
		objStr.toBuf.readObj
	}
	
	override Str toStr() {
		// pretend to be the real object when debugging 
		val?.toStr ?: "null"
	}
}
