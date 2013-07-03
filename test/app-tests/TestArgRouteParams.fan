using web::WebClient

internal class TestArgRouteParams : AppTest {

	Void testP0() {
		verify404(`/route/optional/`)
	}

//	Void testP1() {
//		res := getAsStr(`/route/optional/kick`)
//		verifyEq(res, "kick p2 p3")
//	}
//
//	Void testP2() {
//		res := getAsStr(`/route/optional/kick/ass`)
//		verifyEq(res, "kick ass p3")
//	}
//
//	Void testP3() {
//		res := getAsStr(`/route/optional/kick/ass/baby`)
//		verifyEq(res, "kick ass baby")
//	}
//
//	Void testP4() {
//		verify404(`/route/optional/1/2/3/4`)
//	}
//
//	Void testValEnc() {
//		res := getAsStr(`/route/VALENC/56`)
//		verifyEq(res, "56")
//	}
//
//	Void testUri() {
//		res := getAsStr(`/route/uri/1/2/3`)
//		verifyEq(res, "uri: 1/2/3")
//	}
//
//	Void testList() {
//		res := getAsStr(`/route/list/1/2/3`)
//		verifyEq(res, "uri: [1, 2, 3]")
//	}
//
//	Void testInvalidValEnc() {
//		verify404(`/route/VALENC/penis`)
//	}
}
