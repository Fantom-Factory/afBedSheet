
abstract internal class BsTest : Test {
	
	override Void setup() {
		Log.get("afIoc").level 		= LogLevel.warn
		Log.get("afBedSheet").level = LogLevel.warn
	}
	
	Void verifyBsErrMsg(Str errMsg, |Obj| func) {
		verifyErrMsg(BedSheetErr#, errMsg, func)
	}

	protected Void verifyErrMsg(Type errType, Str errMsg, |Obj| func) {
		try {
			func(4)
		} catch (Err e) {
			if (!e.typeof.fits(errType)) 
				throw Err("Expected $errType got $e.typeof", e)
			verifyEq(errMsg, e.msg)	// this gives the Str comparator in eclipse
			return
		}
		throw Err("$errType not thrown")
	}
	
}
