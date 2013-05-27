
internal const class DefaultErrHandler : ErrHandler {

	 override Void handle(Err err) {
			throw Err()
	 }
	
}
