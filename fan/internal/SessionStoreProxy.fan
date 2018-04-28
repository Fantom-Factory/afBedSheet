using afIoc::RegistryBuilder
using afIoc::Scope
using concurrent::AtomicRef
using wisp::WispSessionStore
using wisp::WispService

internal const class SessionStoreProxy : WispSessionStore {

	private const AtomicRef	sessionStoreRef	:= AtomicRef(null)

	new make(RegistryBuilder bob) {
		sessionStoreType := (Type) bob.options["wisp.sessionStoreProxy"]
		bob.onRegistryStartup |config| {
			config["afBedSheet.sessionStoreProxy"] = |Scope scope| {
				// load serviceByType because that's what we have, and the semantics are different to serviceById
				sessionStoreRef.val = scope.serviceByType(sessionStoreType, false) ?: scope.build(sessionStoreType)
				sessionStore.onStart
			}
		}
		bob.addModule(this)
	}

	override WispService service() {
		Service.find(WispService#, true)
	}

	WispSessionStore sessionStore() {
		sessionStoreRef.val ?: throw HttpStatus.makeErr(503, "Session Store Unavailable\n - Please try again in a few moments")
	}

	override Void onStop() {
		sessionStore.onStop
		sessionStoreRef.val = null
	}
	
	@NoDoc	override Str:Obj? load(Str id)				{ sessionStore.load(id) }
	@NoDoc	override Void save(Str id, Str:Obj? map)	{ sessionStore.save(id, map) }
	@NoDoc	override Void delete(Str id)				{ sessionStore.delete(id) }
}
