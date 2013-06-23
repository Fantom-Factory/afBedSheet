
internal class TestRouteMatcherArgImpl : BsTest {
	
	private Void dummyHandler(Uri uri) {}

	Void testMatch() {
		
		router := RouteMatcherArgImpl(Field.makeSetFunc([
			RouteMatcherArgImpl#.field("valueEncoderSource"):ValueEncoderSource([:])
		]))
		
		r1 := ArgRoute(`/index`,	#dummyHandler)
		r2 := ArgRoute(`/fOO`,		#dummyHandler, "POST")
		r3 := ArgRoute(`/foo`,		#dummyHandler)
		r4 := ArgRoute(`/foobar`,	#dummyHandler)
		
		match := router.match(r1, `/index`, "PUT")
		verifyNull(match)
		
		match = router.match(r1, `/wotever`, "GET")
		verifyNull(match)
		
		match = router.match(r1, `/index`, "GET")
		verifyEq(match.routeBase,	`/index/`)
		verifyEq(match.routeRel,	``)

		match = router.match(r3, `/foo`, "GET")
		verifyEq(match.routeBase,	`/foo/`)
		verifyEq(match.routeRel,	``)

		match = router.match(r2, `/foo/bar/dude`, "POST")
		verifyEq(match.routeBase,	`/fOO/`)
		verifyEq(match.routeRel,	`bar/dude`)

		match = router.match(r4, `/foobar/dude/3`, "GET")
		verifyEq(match.routeBase,	`/foobar/`)
		verifyEq(match.routeRel,	`dude/3`)
		
		match = router.match(r4, `/foobar/dude/3/`, "GET")
		verifyEq(match.routeBase,	`/foobar/`)
		verifyEq(match.routeRel,	`dude/3/`)
		
		match = router.match(r1, `/index?dude=3`, "GET")
		verifyEq(match.routeBase,	`/index/`)
		verifyEq(match.routeRel,	`?dude=3`)
		
		match = router.match(r1, `/InDeX?dude=3`, "GET")
		verifyEq(match.routeBase,	`/index/`)
		verifyEq(match.routeRel,	`?dude=3`)

		match = router.match(r1, `/InDeX/mate?dude=3`, "GET")
		verifyEq(match.routeBase,	`/index/`)
		verifyEq(match.routeRel,	`mate?dude=3`)

		match = router.match(r1, `/InDeX/mate/?dude=3`, "GET")
		verifyEq(match.routeBase,	`/index/`)
		verifyEq(match.routeRel,	`mate/?dude=3`)
	}
}
