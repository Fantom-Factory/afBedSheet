using concurrent

internal const class Utils {
	
	** Usage:
	** 
	**   private static const Log log	:= Utils.getLog(Wotever#)
	static Log getLog(Type type) {
//		Log.get(type.pod.name + "." + type.name)
		type.pod.log
	}

	static Obj:Obj makeMap(Type keyType, Type valType) {
		mapType := Map#.parameterize(["K":keyType, "V":valType])
		return keyType.fits(Str#) ? Map.make(mapType) { caseInsensitive = true } : Map.make(mapType) { ordered = true }
	}
	
	static Str traceErr(Err err, Int maxDepth := 50) {
		b := Buf()	// can't trace to a StrBuf
		err.trace(b.out, ["maxDepth":maxDepth])
		return b.flip.in.readAllStr
	}
	
	static Str prettyPrintMap(Str:Obj? map, Str prefix, Bool sortKeys) {
		maxKeySize := (Int) map.keys.reduce(0) |size, key| { ((Int) size).max(key.size) }
		if (sortKeys) {
			newMap := Str:Obj?[:] { ordered = true } 
			map.keys.sort.each |k| { newMap[k] = map[k] }
			map = newMap
		}
		buf := StrBuf(map.size*50)
		map.each |v, k| {
			key := (k.size == maxKeySize) ? k : "$k "
			buf.add(prefix + key.padr(maxKeySize, '.') + " : " + (v?.toStr ?: "null") + "\n") 
		}
		return buf.toStr
	}

	** A read only copy of the 'Actor.locals' map with the keys sorted alphabetically. Handy for 
	** debugging. Example:
	** 
	**   IocHelper.locals.each |value, key| { echo("$key = $value") }
	** 
	static Str:Obj? locals() {
		Str:Obj? map := [:] { ordered = true }
		Actor.locals.keys.sort.each { map[it] = Actor.locals[it] }
		return map
	}

}
