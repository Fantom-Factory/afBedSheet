
internal class TestRouter : BsTest {
	
	// dummy handlers
	private Void handler1() {}
	private Void handler2() {}
	private Void handler3() {}
	private Void handler4() {}

	Void testRoutesCanNotBeDuplicated() {
		verifyBsErrMsg(BsMsgs.routeAlreadyAdded(`/foo/`, #handler2)) {
			router := RouteSource([
				Route(`/foo`, 	#handler2),
				Route(`/foo/`,	#handler1)
			])
		}

		|->| {
			// same routes with different http methods ARE allowed
			router := RouteSource([
				Route(`/bar/`,		#handler1, "WOT"),
				Route(`/bar/`, 		#handler1, "EVER")
			])
		}()

		// routes are case-insensitive
		verifyBsErrMsg(BsMsgs.routeAlreadyAdded(`/bar/`, #handler1)) {
			router := RouteSource([
				Route(`/bar/`,		#handler1),
				Route(`/BAR/`, 		#handler2)
			])
		}
	}

	Void testRoutesCanNotNest() {
		verifyBsErrMsg(BsMsgs.routesCanNotBeNested(`/foo/bar/`, `/foo/`)) {
			router := RouteSource([
				Route(`/foo`, 		#handler1),
				Route(`/foo/bar`,	#handler1)
			])
		}
		verifyBsErrMsg(BsMsgs.routesCanNotBeNested(`/bar/foo/`, `/bar/`)) {
			router := RouteSource([
				Route(`/bar/foo`,	#handler1),
				Route(`/bar/`, 		#handler1)
			])
		}

		// nested routes with different http methods are still NOT allowed
		verifyBsErrMsg(BsMsgs.routesCanNotBeNested(`/bar/foo/`, `/bar/`)) {
			router := RouteSource([
				Route(`/bar/foo`,	#handler1, "WOT"),
				Route(`/bar/`, 		#handler1, "EVER")
			])
		}
	}

	Void testRoutes() {
		router := RouteSource([
			Route(`/index`,		#handler1),
			Route(`/fOO`,		#handler2, "POST"),
			Route(`/foo`,		#handler3),
			Route(`/foobar`,	#handler4)
		])
		
		verifyRouteNotFoundErrMsg(BsMsgs.routeNotFound(`/index`)) {
			match := router.match(`/index`, "PUT")
		}
		
		verifyRouteNotFoundErrMsg(BsMsgs.routeNotFound(`/wotever`)) {
			match := router.match(`/wotever`, "GET")
		}
		
		match := router.match(`/index`, "GET")
		verifyEq(match.routeBase,	`/index/`)
		verifyEq(match.routeRel,	``)
		verifyEq(match.handler, 	#handler1)
		verifyEq(match.httpMethod,	"GET")

		match = router.match(`/foo`, "GET")
		verifyEq(match.routeBase,	`/foo/`)
		verifyEq(match.routeRel,	``)
		verifyEq(match.handler, 	#handler3)
		verifyEq(match.httpMethod,	"GET")

		match = router.match(`/foo/bar/dude`, "POST")
		verifyEq(match.routeBase,	`/fOO/`)
		verifyEq(match.routeRel,	`bar/dude`)
		verifyEq(match.handler, 	#handler2)
		verifyEq(match.httpMethod,	"POST")

		match = router.match(`/foobar/dude/3`, "GET")
		verifyEq(match.routeBase,	`/foobar/`)
		verifyEq(match.routeRel,	`dude/3`)
		verifyEq(match.handler, 	#handler4)
		verifyEq(match.httpMethod,	"GET")
		
		match = router.match(`/foobar/dude/3/`, "GET")
		verifyEq(match.routeBase,	`/foobar/`)
		verifyEq(match.routeRel,	`dude/3/`)
		verifyEq(match.handler, 	#handler4)
		verifyEq(match.httpMethod,	"GET")
		
		match = router.match(`/index?dude=3`, "GET")
		verifyEq(match.routeBase,	`/index/`)
		verifyEq(match.routeRel,	`?dude=3`)
		verifyEq(match.handler, 	#handler1)
		verifyEq(match.httpMethod,	"GET")
		
		match = router.match(`/InDeX?dude=3`, "GET")
		verifyEq(match.routeBase,	`/index/`)
		verifyEq(match.routeRel,	`?dude=3`)
		verifyEq(match.handler, 	#handler1)
		verifyEq(match.httpMethod,	"GET")

		match = router.match(`/InDeX/mate?dude=3`, "GET")
		verifyEq(match.routeBase,	`/index/`)
		verifyEq(match.routeRel,	`mate?dude=3`)
		verifyEq(match.handler, 	#handler1)
		verifyEq(match.httpMethod,	"GET")

		match = router.match(`/InDeX/mate/?dude=3`, "GET")
		verifyEq(match.routeBase,	`/index/`)
		verifyEq(match.routeRel,	`mate/?dude=3`)
		verifyEq(match.handler, 	#handler1)
		verifyEq(match.httpMethod,	"GET")
	}
}
