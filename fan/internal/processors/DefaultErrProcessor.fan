
** Converts an Err into a `HttpStatus` with a status code of 500 - Internal Server Error. 
internal const class DefaultErrProcessor : ErrProcessor {
	
	override Obj process(Err err) {
		HttpStatus(500, "Internal Server Error", err)
	}
}
