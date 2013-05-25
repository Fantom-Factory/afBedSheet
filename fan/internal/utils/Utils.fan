
class Utils {
	
	static Log getLog(Type type) {
//		Log.get(type.pod.name + "." + type.name)
		type.pod.log
	}

	static Obj:Obj makeMap(Type keyType, Type valType) {
		mapType := Map#.parameterize(["K":keyType, "V":valType])
		return keyType.fits(Str#) ? Map.make(mapType) { caseInsensitive = true } : Map.make(mapType) { ordered = true }
	}
}
