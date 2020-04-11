
class TestUriTrees : Test {

	// Test Basic Functionality
	//   1 - Create myTree
	//   2 - Create a basic tree structure; `/foo`, `/foo2/bar`
	//   3 - Verify get for both tree structures
	Void testBasic() {
		myTree := RouteMatcher()

		myTree.set(`/foo`, "test")
		myTree.set(`/foo2/bar`, "test2")

		verifyEq(myTree.get(`/foo`		).handler, "test")
		verifyEq(myTree.get(`/foo2/bar`	).handler, "test2")
		verifyEq(myTree.get(`/wot/ever`		), null)
		verifyEq(myTree.get(`/foo/ever`		), null)
		verifyEq(myTree.get(`/foo2/bar/ever`), null)
	}

	// Test Case Sensitivity -- Verify that get calls are case insensitive
	//   1 - Create myTree
	//   2 - Create a basic tree structure; `/foo`, `/foo2/bar`
	//   3 - Verify get for both tree structures with random upper case letters
	Void testCaseSensitivity() {
		myTree := RouteMatcher()

		myTree.set(`/foo`, "test")
		myTree.set(`/foo2/bar`, "test2")

		verifyEq(myTree.get(`/fOO`).handler, "test")
		verifyEq(myTree.get(`/foo2/BAR`).handler, "test2")
		verifyEq(myTree.get(`/fOO2/BAR`).handler, "test2")
	}

	// Test Trailing Slash-- Verify that get calls process regardless if a trailing slash exists
	//   1 - Create myTree
	//   2 - Create a basic tree structure; `/foo`, `/foo2/bar`
	//   3 - Verify get for both tree structures with gets that end in a slash
	Void testTrailingSlash() {
		myTree := RouteMatcher()

		myTree.set(`/foo`, "test")
		myTree.set(`/foo2/bar`, "test2")

		verifyEq(myTree.get(`/foo/`).handler, "test")
		verifyEq(myTree.get(`/foo2/bar/`).handler, "test2")
	}

	// Test wildcard functionality
	//	 1 - Create myTree
	//   2 - Create a basic tree structure; `/*`, `/foo/*`
	//   3 - Verify get for both tree structures
	//   4 - Verify wildcard return
	Void testWildcard() {
		myTree := RouteMatcher()
		myTree.set(`/*`, "test")
		myTree.set(`/foo/*`, "test2")
		myTree.set(`/foo2/*/edit/*`, "test3")

		verifyEq(myTree.get(`/wildCard`).handler, 			"test")
		verifyEq(myTree.get(`/wildCard`).wildcardSegments,	["wildCard"])

		verifyEq(myTree.get(`/foo/wildCard`).handler,			"test2")
		verifyEq(myTree.get(`/foo/wildCard`).wildcardSegments,	["wildCard"])

		verifyEq(myTree.get(`/foo2/wildCard/edit/12`).handler,			"test3")
		verifyEq(myTree.get(`/foo2/wildCard/edit/12`).wildcardSegments,	["wildCard", "12"])


		verifyEq(myTree.get(`/foo/foo\/b\#ar`).handler, 			"test2")
	}

	// Test map preferences; absoluteMap > routeTreeMap
	//   1 - Create myTree
	//   2 - Create tree structure; `/foo`, `/foo/bar`
	//   3 - Verify get for  '/foo'
	Void testMapPrefrences() {
		myTree := RouteMatcher()
		myTree.set(`/foo`, "test")
		myTree.set(`/foo/bar`, "test2")

		verifyEq(myTree.get(`/foo`).handler, "test")
	}

	// Test explicit preferences; explicit path > wildcard path
	//   1 - Create myTree
	//   2 - Create tree structure; `/foo`, `/*`
	//   3 - Verify get for  '/foo'
	Void testExplicitPreferences() {
		myTree := RouteMatcher()
		myTree.set(`/foo`, "test")
		myTree.set(`/*`, "test2")

		verifyEq(myTree.get(`/foo`).handler, "test")
	}

	// Test Canonical Url
	//   1 - Create myTree
	//   2 - Create tree structure; `/foo`, `/foo2/bar/truck/*`
	//   3 - Verify handler and canonical get for single, and nested trees.
	Void testCanonical() {
		myTree := RouteMatcher()
		myTree.set(`/foo`, "test")
		myTree.set(`/foo2/bar/truck/*`, "test2")

		verifyEq(myTree.get(`/fOO`).handler, "test")
		verifyEq(myTree.get(`/fOO`).canonicalUrl, `/foo`)

		verifyEq(myTree.get(`/foO2/BaR/TrucK/What`).handler, "test2")
		verifyEq(myTree.get(`/foO2/BaR/TrucK/What`).requestUrl, `/foO2/BaR/TrucK/What`)
		verifyEq(myTree.get(`/foO2/BaR/TrucK/What`).canonicalUrl, `/foo2/bar/truck/what`)
	}

	// Test Double Wildcard
	//   1 - Create myTree
	//   2 - Create tree structure; `/my/images/**`, `/**`
	//   3 - Verify handler, canonical, wildcardSegments, and remainingSegments for nested, and single uri structures.
	Void testDoubleWildcard() {
		myTree := RouteMatcher()
		myTree.set(`/my/images/**`, "test")
		myTree.set(`/**`, "test2")

		verifyEq(myTree.get(`/my/images/get/file/foo.png`).handler, "test")
		verifyEq(myTree.get(`/My/Images/get/file/fOo.png`).canonicalUrl, `/my/images/get/file/foo.png`)
		verifyEq(myTree.get(`/my/images/get/file/foo.png`).wildcardSegments, Str[,])
		verifyEq(myTree.get(`/my/images/get/file/foo.png`).remainingSegments, ["get", "file", "foo.png"])

		verifyEq(myTree.get(`/my/images/get/file/foo.png`).requestUrl, `/my/images/get/file/foo.png`)

		verifyEq(myTree.get(`/foo.png`).handler, "test2")
		verifyEq(myTree.get(`/fOo.png`).canonicalUrl, `/foo.png`)
		verifyEq(myTree.get(`/foo.png`).wildcardSegments, Str[,])
		verifyEq(myTree.get(`/foo.png`).remainingSegments, ["foo.png"])
	}
}
