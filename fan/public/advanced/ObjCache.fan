using afIoc3
using afConcurrent

@NoDoc	// Advanced use only
const class ObjCache {
	private const Type[] 		serviceTypeCache
	private const AtomicMap		constTypeCache		:= AtomicMap()
	private const AtomicList	autobuildTypeCache	:= AtomicList()
	
	@Inject	private const Registry 		registry

	new make(|This|in) {
		in(this) 
		this.serviceTypeCache = registry.serviceDefs.vals.map { it.type }
	}

	@Operator
	Obj? get(Type? type) {
		if (type == null)
			return null
		
		obj := null
		if (serviceTypeCache.contains(type))
			obj = registry.dependencyByType(type)

		if (constTypeCache.containsKey(type))
			obj = constTypeCache[type]
		
		if (autobuildTypeCache.contains(type))
			obj = registry.autobuild(type)
		
		if (obj == null) {
			if (type.isConst) {
				obj = registry.autobuild(type)
				constTypeCache.set(type, obj)
				
			} else {
				autobuildTypeCache.add(type)
				obj = registry.autobuild(type)
			}
		}

		return obj
	}
}
