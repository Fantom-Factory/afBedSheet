
class TestRouteTree : Test {

	Void testBasic() {
		myTree := RouteMatcher()
		myTree.set(`/`,			"root")
		myTree.set(`/foo`,		"test")
		myTree.set(`/foo2/bar`,	"test2")

		verifyEq(myTree.get(`/`				).handler, 		"root")
		verifyEq(myTree.get(`/foo`			).handler, 		"test")
		verifyEq(myTree.get(`/foo`			).canonicalUrl,	`/foo`)
		verifyEq(myTree.get(`/foo2/bar`		).handler,		"test2")
		verifyEq(myTree.get(`/foo2/bar`		).canonicalUrl,	`/foo2/bar`)
		verifyEq(myTree.get(`/wot/ever`		), null)
		verifyEq(myTree.get(`/foo/ever`		), null)
		verifyEq(myTree.get(`/foo2/bar/ever`), null)
	}

	Void testCaseInsensitivity() {
		myTree := RouteMatcher()
		myTree.set(`/foo`,		"test")
		myTree.set(`/foo2/baR`,	"test2")

		verifyEq(myTree.get(`/fOO`		).handler,		"test")
		verifyEq(myTree.get(`/fOO`		).canonicalUrl,	`/foo`)
		verifyEq(myTree.get(`/foo2/BAR`	).handler,		"test2")
		verifyEq(myTree.get(`/foo2/BAR`	).canonicalUrl,	`/foo2/baR`)
	}

	Void testTrailingSlash() {
		myTree := RouteMatcher()
		myTree.set(`/foo`,		"test")
		myTree.set(`/foo2/bar`,	"test2")

		verifyEq(myTree.get(`/foo/`		).handler, "test")
		verifyEq(myTree.get(`/foo2/bar/`).handler, "test2")

		// I've no requirement for this, but I assume leading slashes are optional too
		verifyEq(myTree.get(`foo`		).handler, "test")
		verifyEq(myTree.get(`foo2/bar`	).handler, "test2")
	}

	Void testWildcard() {
		myTree := RouteMatcher()
		myTree.set(`/*`,				"test")
		myTree.set(`/foo/*`,			"test2")
		myTree.set(`/foo2/*/edit/*`,	"test3")

		verifyEq(myTree.get(`/wildCard`				).handler,		"test")
		verifyEq(myTree.get(`/wildCard`				).wildcards,	Obj["wildCard"])

		verifyEq(myTree.get(`/foo/wildCard`			).handler,		"test2")
		verifyEq(myTree.get(`/foo/wildCard`			).wildcards,	Obj["wildCard"])

		verifyEq(myTree.get(`/foo2/wildCard/edit/12`).handler,		"test3")
		verifyEq(myTree.get(`/foo2/wildCard/edit/12`).wildcards,	Obj["wildCard", "12"])

		// move to dodge
		verifyEq(myTree.get(`/foo/foo\/b\#ar`		).handler, 		"test2")
		verifyEq(myTree.get(`/foo/foo\/b\#ar`		).wildcards,	Obj["foo\\/b\\#ar"])	// # is escaped
	}

	Void testMapPrefrences() {
		myTree := RouteMatcher()
		myTree.set(`/foo`,		"test")
		myTree.set(`/foo/bar`,	"test2")

		verifyEq(myTree.get(`/foo`		).handler, "test")
		verifyEq(myTree.get(`/foo/bar`	).handler, "test2")
	}

	Void testExplicitPreferences() {
		myTree := RouteMatcher()
		myTree.set(`/*`,	"test")
		myTree.set(`/**`,	"test2")
		myTree.set(`/foo`,	"test3")
		
		verifyEq(myTree.get(`/foo`		).handler, "test3")
		verifyEq(myTree.get(`/bar`		).handler, "test")
		verifyEq(myTree.get(`/foo/bar`	).handler, "test2")
	}

	Void testCanonical() {
		myTree := RouteMatcher()
		myTree.set(`/foo`,				"test")
		myTree.set(`/foo2/bar/truck/*`,	"test2")

		verifyEq(myTree.get(`/fOO`).handler,		"test")
		verifyEq(myTree.get(`/fOO`).canonicalUrl,	`/foo`)

		verifyEq(myTree.get(`/foO2/BaR/TrucK/What`)?.handler,		"test2")
		verifyEq(myTree.get(`/foO2/BaR/TrucK/What`)?.canonicalUrl,	`/foo2/bar/truck/What`)
	}

	Void testDoubleWildcard() {
		myTree := RouteMatcher()
		myTree.set(`/my/images/**`, "test")
		myTree.set(`/**`, "test2")

		verifyEq(myTree.get(`/my/images/get/file/FOo.png`).handler,			"test")
		verifyEq(myTree.get(`/My/Images/get/file/FOo.png`).canonicalUrl,	`/my/images/get/file/FOo.png`)
		verifyEq(myTree.get(`/my/images/get/file/FOo.png`).wildcards,		Obj[`/get/file/FOo.png`])

		verifyEq(myTree.get(`/FOo.png`).handler,		"test2")
		verifyEq(myTree.get(`/FOo.png`).canonicalUrl,	`/FOo.png`)
		verifyEq(myTree.get(`/FOo.png`).wildcards,		Obj[`/FOo.png`])
	}
}

internal class RouteMatcher {
	private RouteTreeBuilder routeTreeBob
	private RouteTree?		 routeTree
	
	new make() {
		this.routeTreeBob = RouteTreeBuilder()
	}
	
	@Operator
	This set(Uri url, Obj handler) {
		routeTreeBob.set(url.path, handler)
		return this
	}
	
	@Operator
	RouteMatch? get(Uri url) {
		routeTreeBob.toConst.get(url.path)
	}    
}
