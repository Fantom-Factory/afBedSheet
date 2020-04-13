using afBeanUtils
using afConcurrent

** A 'TypeCoercer' that caches its conversion methods.
internal const class CachingTypeCoercer : TypeCoercer {
	private const AtomicMap cache := AtomicMap()

	** Cache the conversion functions
	override protected |Obj->Obj|? createCoercionFunc(Type fromType, Type toType) {
		key	:= "${fromType.qname}->${toType.qname}"
		// try get() first to avoid creating the func - method.func binding doesn't work in JS
		return cache.containsKey(key)
			? cache.get(key)
			: cache.getOrAdd(key) { doCreateCoercionFunc(fromType, toType) } 
	}

	** Clears the function cache 
	Void clear() {
		cache.clear
	}
}
