
internal const class Utils {
	
	** private static const Log log	:= Utils.getLog(Wotever#)
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
}
