
abstract internal class BsTest : Test {
	
	override Void setup() {
		Log.get("afIoc").level 		= LogLevel.warn
		Log.get("afBedSheet").level = LogLevel.warn
	}
	
	Void verifyBsErrMsg(Str errMsg, |Obj| func) {
		verifyErrMsg(BedSheetErr#, errMsg, func)
	}
	
}
