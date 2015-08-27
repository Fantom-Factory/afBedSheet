using afIoc
using afConcurrent

internal const class FieldProcessor : ResponseProcessor {
	@Inject private const ObjCache		objCache

	new make(|This|in) { in(this)}

	override Obj process(Obj response) {
		field	:= (Field) response
		parent	:= field.isStatic ? null : objCache[field.parent]
		result	:= field.get(parent)
		return (result == null) ? false : result
	}
}
