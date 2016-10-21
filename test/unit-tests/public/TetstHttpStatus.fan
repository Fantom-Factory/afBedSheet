
class TetstHttpStatus : Test {
	
	Void testNonStandardCodes() {
		// just check it doesn't cause an NPE
		HttpStatus.makeErr(5555)
	}
}
