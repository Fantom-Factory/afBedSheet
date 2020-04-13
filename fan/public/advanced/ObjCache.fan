using afIoc
using afConcurrent

@NoDoc	// Advanced use only
const class ObjCache {
	private const Type[] 		serviceTypeCache
	private const AtomicMap		constTypeCache		:= AtomicMap()
	private const AtomicList	autobuildTypeCache	:= AtomicList()
	
	@Inject	private const |->Scope|	activeScopeFn

	new make(|This|in) {
		in(this) 
		this.serviceTypeCache = activeScopeFn().registry.serviceDefs.vals.map { it.type }
	}

	@Operator
	Obj? get(Type? type) {
		if (type == null)
			return null
		
		obj := null
		if (serviceTypeCache.contains(type))
			obj = activeScopeFn().serviceByType(type)

		if (constTypeCache.containsKey(type))
			obj = constTypeCache[type]
		
		if (autobuildTypeCache.contains(type))
			obj = activeScopeFn().build(type)
		
		if (obj == null) {
			if (type.isConst) {
				obj = activeScopeFn().build(type)
				constTypeCache.set(type, obj)
				
			} else {
				autobuildTypeCache.add(type)
				obj = activeScopeFn().build(type)
			}
		}

		return obj
	}
}
