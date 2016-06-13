using afIoc
using afConcurrent

@NoDoc	// Advanced use only
const class ObjCache {
	private const Type[] 		serviceTypeCache
	private const AtomicMap		constTypeCache		:= AtomicMap()
	private const AtomicList	autobuildTypeCache	:= AtomicList()
	
	@Inject	private const |->Scope|	activeScope

	new make(|This|in) {
		in(this) 
		this.serviceTypeCache = activeScope().registry.serviceDefs.vals.map { it.type }
	}

	@Operator
	Obj? get(Type? type) {
		if (type == null)
			return null
		
		obj := null
		if (serviceTypeCache.contains(type))
			obj = activeScope().serviceByType(type)

		if (constTypeCache.containsKey(type))
			obj = constTypeCache[type]
		
		if (autobuildTypeCache.contains(type))
			obj = activeScope().build(type)
		
		if (obj == null) {
			if (type.isConst) {
				obj = activeScope().build(type)
				constTypeCache.set(type, obj)
				
			} else {
				autobuildTypeCache.add(type)
				obj = activeScope().build(type)
			}
		}

		return obj
	}
}
