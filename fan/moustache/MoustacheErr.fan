
const class MoustacheErr : Err {

	const SrcLocation srcLoc

	new make(SrcLocation srcLoc, Str msg, Err? cause := null) : super(msg, cause) {
		this.srcLoc = srcLoc
	}
}
