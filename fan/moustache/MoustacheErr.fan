
const class MoustacheErr : Err {

	internal const SrcLocation srcLoc

	internal new make(SrcLocation srcLoc, Str msg, Err? cause := null) : super(msg, cause) {
		this.srcLoc = srcLoc
	}
	
	override Str toStr() {
		// TODO: print srcLoc
		super.toStr
	}
}
