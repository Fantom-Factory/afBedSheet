
abstract internal class ConfigTest : Test {
	
	Void verifyConfigErrMsg(Str errMsg, |Obj| func) {
		verifyErrTypeMsg(ConfigErr#, errMsg, func)
	}

	private Void verifyErrTypeMsg(Type errType, Str errMsg, |Obj| func) {
		try {
			func(4)
		} catch (Err e) {
			e = e.cause	// unwrap IocErr
			
			if (!e.typeof.fits(errType)) 
				throw Err("Expected $errType got $e.typeof", e)
			msg := e.msg
			if (msg != errMsg)
				verifyEq(errMsg, msg)	// this gives the Str comparator in eclipse
//				throw Err("Expected: \n - $errMsg \nGot: \n - $msg")
			return
		}
		throw Err("$errType not thrown")
	}
	
}
