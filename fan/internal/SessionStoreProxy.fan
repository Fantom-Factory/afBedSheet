using afIoc::RegistryBuilder
using afIoc::Scope
using concurrent::AtomicRef
using wisp::WispSessionStore

internal const class SessionStoreProxy : WispSessionStore {
	
	private const AtomicRef	sessionStoreRef	:= AtomicRef(null)

	new make(RegistryBuilder bob) {
		sessionStoreType := (Type) bob.options["wisp.sessionStoreProxy"]
		bob.onRegistryStartup |config| {
			config["afBedSheet.sessionStoreProxy"] = |Scope scope| {
				sessionStoreRef.val = scope.serviceById(sessionStoreType.qname, false) ?: scope.build(sessionStoreType)
			}
		}
		bob.addModule(this)
	}
	
	WispSessionStore sessionStore() {
		sessionStoreRef.val ?: throw HttpStatus.makeErr(503, "Session Store Unavailable\n - Please try again in a few moments")
	}
	
	@NoDoc	override Str:Obj? load(Str id)				{ sessionStore.load(id) }
	@NoDoc	override Void save(Str id, Str:Obj? map)	{ sessionStore.save(id, map) }
	@NoDoc	override Void delete(Str id)				{ sessionStore.delete(id) }
}
