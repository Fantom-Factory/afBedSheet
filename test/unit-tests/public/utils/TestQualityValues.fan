
class TestQualityValues : Test {
	
	Void testParseOne() {
		qvs	:= QualityValues("gzip")
		
		verifyEq(qvs.size, 1)
		verifyEq(qvs["gzip"], 1f)
		verifyEq(qvs["deflate"], 0f)
		verifyEq(qvs.accepts("gzip"), true)
		verifyEq(qvs.accepts("deflate"), false)
	}

	Void testParseMany() {
		qvs	:= QualityValues("gzip, deflate")
		
		verifyEq(qvs.size, 2)
		verifyEq(qvs["gzip"], 1f)
		verifyEq(qvs["deflate"], 1f)
		verifyEq(qvs.accepts("gzip"), true)
		verifyEq(qvs.accepts("deflate"), true)
		verifyEq(qvs.accepts("wotever"), false)
	}

	Void testParseQValues() {
		qvs	:= QualityValues("audio/*; q=0.2, audio/basic")
		
		verifyEq(qvs.size, 2)
		verifyEq(qvs["audio/*"], 0.2f)
		verifyEq(qvs["audio/basic"], 1f)
		verifyEq(qvs.accepts("audio/*"), true)
		verifyEq(qvs.accepts("audio/basic"), true)
		verifyEq(qvs.accepts("wotever"), false)

		
		qvs	= QualityValues("application/*")
		
		verifyEq(qvs.size, 1)
		verifyEq(qvs["application/xhtml+xml"], 1f)
		verifyEq(qvs.accepts("application/*"), true)
		verifyEq(qvs.accepts("application/basic"), true)
		verifyEq(qvs.accepts("wotever"), false)
	}

	Void testParseQValues2() {
		qvs	:= QualityValues("gzip;q=1.0, identity; q=0.5, *;q=0")
		
		verifyEq(qvs.size, 3)
		verifyEq(qvs["gzip"], 1.0f)
		verifyEq(qvs["identity"], 0.5f)
		verifyEq(qvs["*"], 0.0f)
		verifyEq(qvs.accepts("gzip"), true)
		verifyEq(qvs.accepts("identity"), true)
		verifyEq(qvs.accepts("*"), false)
		verifyEq(qvs.accepts("wotever"), false)
	}

	Void testParseQValuesWithParams() {
		// https://www.rfc-editor.org/rfc/rfc9110.html#name-accept
		
		// test these are in the correct order
		qvs := QualityValues("text/*, text/plain, text/plain;format=flowed, */*")
		verifyEq(qvs.size, 4)
		verifyEq(qvs.qvalues.keys[0], "text/plain;format=flowed")
		verifyEq(qvs.qvalues.keys[1], "text/plain")
		verifyEq(qvs.qvalues.keys[2], "text/*")
		verifyEq(qvs.qvalues.keys[3], "*/*")
		verifyEq(qvs.qvalues.vals[0], 1.0f)
		verifyEq(qvs.qvalues.vals[1], 1.0f)
		verifyEq(qvs.qvalues.vals[2], 1.0f)
		verifyEq(qvs.qvalues.vals[3], 1.0f)
		verifyEq(qvs.toStr, "text/plain;format=flowed, text/plain, text/*, */*")
		
		qvs = QualityValues("text/*;q=0.3, text/plain;q=0.7, text/plain;format=flowed, text/plain;format=fixed;q=0.4, */*;q=0.5")
		verifyEq(qvs.size, 5)
		verifyEq(qvs.qvalues.keys[0], "text/plain;format=flowed")
		verifyEq(qvs.qvalues.keys[1], "text/plain")
		verifyEq(qvs.qvalues.keys[2], "*/*")
		verifyEq(qvs.qvalues.keys[3], "text/plain;format=fixed")
		verifyEq(qvs.qvalues.keys[4], "text/*")
		verifyEq(qvs.toStr, "text/plain;format=flowed, text/plain;q=0.7, */*;q=0.5, text/plain;format=fixed;q=0.4, text/*;q=0.3")

		verifyEq(qvs.get("text/plain;format=flowed"),	1.0f)
		verifyEq(qvs.get("text/plain"),					0.7f)
		verifyEq(qvs.get("text/html"),					0.3f)
		verifyEq(qvs.get("image/jpeg"),					0.5f)
		verifyEq(qvs.get("text/plain;format=fixed"),	0.4f)
		verifyEq(qvs.get("text/html;level=3"),			0.3f)
	}
	
	Void testParseErr1() {
		verifyErrMsg(ParseErr#, "q is not a float: gzip;q=none") {
			qvs	:= QualityValues("gzip;q=none")
		}
	}
	
	Void testParseErr2() {
		verifyErrMsg(ParseErr#, "q should be 0..1: gzip;q=-0.3") {
			qvs	:= QualityValues("gzip;q=-0.3")
		}
	}
	
	Void testParseErr3() {
		verifyErrMsg(ParseErr#, "q should be 0..1: gzip;q=69") {
			qvs	:= QualityValues("gzip;q=69")
		}
	}
	
	Void testParseReturnsNull() {
		qvs	:= QualityValues("gzip;q=69", false)
		verifyNull(qvs)
	}
	
	Void testToStr() {
		qvs	:= QualityValues("*;q=0, identity; q=0.5, deflate; q=0.256, gzip;q=1.0")
		verifyEq(qvs.toStr, "gzip;q=1.0, identity;q=0.5, deflate;q=0.256, *;q=0.0")
	}
	
	
	Void testContainsMediaWildCards() {
		qvs	:= QualityValues("*")
		verifyEq(qvs.contains("text"), true)
	}

	Void testContainsSubWildCards() {
		qvs	:= QualityValues("text/*")
		verifyEq(qvs.contains("text/*"), true)
		verifyEq(qvs.contains("text/html"), true)
		verifyEq(qvs.contains("text"), false)
		verifyEq(qvs.contains("app/html"), false)
	}
	
	Void testAcceptMediaWildCards() {
		qvs	:= QualityValues("*")
		verifyEq(qvs.accepts("text"), true)

		qvs	= QualityValues("*; q=0")
		verifyEq(qvs.accepts("text"), false)
	}

	Void testAcceptSubWildCards() {
		qvs	:= QualityValues("text/*")
		verifyEq(qvs.accepts("text/*"), true)
		verifyEq(qvs.accepts("text/html"), true)
		verifyEq(qvs.accepts("text"), false)
		verifyEq(qvs.accepts("app/html"), false)

		qvs	= QualityValues("app/*, text/*; q=0")
		verifyEq(qvs.accepts("text/*"), false)
		verifyEq(qvs.accepts("text/html"), false)
		verifyEq(qvs.accepts("text"), false)
		verifyEq(qvs.accepts("app"), false)
		verifyEq(qvs.accepts("app/html"), true)

		qvs	= QualityValues("*, text/*; q=0")	// the "*;q=1.0" means everything is accepted!
		verifyEq(qvs.accepts("text/*"), true)
		verifyEq(qvs.accepts("text/html"), true)
		verifyEq(qvs.accepts("text"), true)
		verifyEq(qvs.accepts("app/html"), true)
	}
}
