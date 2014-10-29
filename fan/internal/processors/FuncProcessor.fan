using afIoc::Inject

internal const class FuncProcessor : ResponseProcessor {
	
	override Obj process(Obj response) {
		func	:= (Func) response
		result	:= (Obj?) func.call
		return result ?: false
	}
}

// FIXME: Fantom bug - need internet!
class Example {
	Void main() {
		// Compilation Err -> Cannot use '?:' operator on non-nullable type 'sys::Obj'
		res := (Obj?) #main.func.call ?: "null"
	}
}
