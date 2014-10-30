using afIoc

internal const class FuncProcessor : ResponseProcessor {
	@Inject	private const ObjCache	objCache

	new make(|This|in) { in(this)}
	
	override Obj process(Obj response) {
		func	:= (Func) response
		args	:= [,] 
		func.params.each {
			if (!it.hasDefault)
				args.add(objCache[it.type])
		}
		result	:= (Obj?) func.callList(args)
		return result ?: false
	}
}

// FIXME: Fantom bug - need internet!
@NoDoc
class Example {
	Void main() {
		// Compilation Err -> Cannot use '?:' operator on non-nullable type 'sys::Obj'
		res := (Obj?) #main.func.call ?: "null"
	}
}
