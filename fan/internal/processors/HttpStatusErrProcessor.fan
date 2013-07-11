
** Extracts the `HttpStatus` from `HttpStatusErr`.
internal const class HttpStatusErrProcessor : ErrProcessor {
	
	internal new make(|This|in) { in(this) }
	
	override Obj process(Err err) {
		httpStatusErr := (HttpStatusErr) err
		return httpStatusErr.httpStatus
	}
}

