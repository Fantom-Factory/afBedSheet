
internal const class DefaultErrProcessor : ErrProcessor {
	
	override Obj process(Err err) {
		HttpStatus(500, "Internal Server Error", err)
	}
}
