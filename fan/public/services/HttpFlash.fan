using afIoc
using afConcurrent

** (Service) - Stores values from one HTTP request to the next. 
** The values stored must be '@Serializable'.
const mixin HttpFlash {
	
	@Operator
	abstract Obj? get(Str name)

	** The given value must be serializable.
	@Operator 
	abstract Void set(Str name, Obj? val)
	
	** Internal method - don't come crying to me when I delete it!
	@NoDoc
	abstract Void setReq([Str:Obj?]? req)
	
	** Internal method - don't come crying to me when I delete it!
	@NoDoc
	abstract [Str:Obj?]? getRes()
}

internal const class HttpFlashImpl : HttpFlash {
	@Inject private const LocalMap req
	@Inject private const LocalMap res
	
	new make(|This|in) { in(this) }
	
	override Obj? get(Str name) {
		res.containsKey(name) ? res[name] : req[name]
	}

	override Void set(Str name, Obj? val) {
		res[name] = val
	}
	
	override Void setReq([Str:Obj?]? req) {
		if (req != null)
			this.req.map = req 
	}

	override [Str:Obj?]? getRes() {
		res.isEmpty ? null : res.map // map doesn't need to be immutable, just serialisable
	}
}
