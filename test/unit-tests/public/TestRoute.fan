
internal class TestRoute : BsTest {
	
	Void foo() { }
	Void handler1() { }
	Void handler2(Str p1) { }
	Void handler3(Str p1, Int p2) { }
	Void handler4(Str p1, Int p2 := 69) { }
	Void handler5(Str? p1 := null, Obj p2 := 69) { }
	
	Void bar1(Str a, Str b) { }
	Void bar2(Str? a, Str? b) { }
	Void bar3(Str? a, Str? b := "") { }
	Void bar4(Str? a, Str b := "") { }

	Void testUriPathOnly() {
		verifyBsErrMsg(BsErrMsgs.routeShouldBePathOnly(`http://www.alienfactory.co.uk/`)) {
			r := Route(`http://www.alienfactory.co.uk/`, #foo)
		}
	}

	Void testUriStartWithSlash() {
		verifyBsErrMsg(BsErrMsgs.routeShouldStartWithSlash(`foo/bar`)) {
			r := Route(`foo/bar`, #foo)
		}
	}	

	Void testHttpMethodMismatch() {
		match := Route(`/index`, #foo).match(`/index`, "POST")
		verifyNull(match)
	}
	
	Void testMatchRegex() {
		Str?[]? match
		
		match = Route(Regex<|(?i)^\/index$|>, #foo).matchUri(`/index`)
		verifyEq(match.size,	0)

		match = Route(Regex<|(?i)^\/index\/(.*?)$|>, #foo).matchUri(`/index/dude`)
		verifyEq(match.size,	1)
		verifyEq(match[0],		"dude")
		
		match = Route(Regex<|(?i)^\/foobar\/(.*?)$|>, #foo, "GET", true)
		.matchUri(`/foobar/dude/2/argh`)
		verifyEq(match.size,	3)
		verifyEq(match[0],		"dude")
		verifyEq(match[1],		"2")
		verifyEq(match[2],		"argh")
	}
	
	Void testMatchGlobFromDocs() {
		Str?[]? match

		match = Route(`/user/*`, #foo).matchUri(`/user/`)
		verifyEq(match.size,	1)
		verifyEq(match[0],		null)
		match = Route(`/user/*`, #foo).matchUri(`/user/42`)
		verifyEq(match.size,	1)
		verifyEq(match[0],		"42")
		match = Route(`/user/*`, #foo).matchUri(`/user/42/`)
		verifyNull(match)
		match = Route(`/user/*`, #foo).matchUri(`/user/42/dee`)
		verifyNull(match)

		match = Route(`/user/*/*`, #foo).matchUri(`/user/`)
		verifyNull(match)
		match = Route(`/user/*/*`, #foo).matchUri(`/user/42`)
		verifyNull(match)
		match = Route(`/user/*/*`, #foo).matchUri(`/user/42/`)
		verifyEq(match.size,	2)
		verifyEq(match[0],		"42")
		verifyEq(match[1],		null)
		match = Route(`/user/*/*`, #foo).matchUri(`/user/42/dee`)
		verifyEq(match.size,	2)
		verifyEq(match[0],		"42")
		verifyEq(match[1],		"dee")

		match = Route(`/user/**`, #foo).matchUri(`/user/`)
		verifyEq(match.size,	1)
		verifyEq(match[0],		null)
		match = Route(`/user/**`, #foo).matchUri(`/user/42`)
		verifyEq(match.size,	1)
		verifyEq(match[0],		"42")
		match = Route(`/user/**`, #foo).matchUri(`/user/42/`)
		verifyEq(match.size,	1)
		verifyEq(match[0],		"42")
		match = Route(`/user/**`, #foo).matchUri(`/user/42/dee`)
		verifyEq(match.size,	2)
		verifyEq(match[0],		"42")
		verifyEq(match[1],		"dee")

		match = Route(`/user/***`, #foo).matchUri(`/user/`)
		verifyEq(match.size,	1)
		verifyEq(match[0],		null)
		match = Route(`/user/***`, #foo).matchUri(`/user/42`)
		verifyEq(match.size,	1)
		verifyEq(match[0],		"42")
		match = Route(`/user/***`, #foo).matchUri(`/user/42/`)
		verifyEq(match.size,	1)
		verifyEq(match[0],		"42/")
		match = Route(`/user/***`, #foo).matchUri(`/user/42/dee`)
		verifyEq(match.size,	1)
		verifyEq(match[0],		"42/dee")
	}

	Void testMatchGlob() {
		Str?[]? match
		
		match = Route(`/index`, #foo).matchUri(`/wotever`)
		verifyNull(match)
		
		match = Route(`/index`, #foo).matchUri(`/index`)
		verifyEq(match.size,	0)

		match = Route(`/foo/?`, #foo).matchUri(`/foo`)
		verifyEq(match.size,	0)

		match = Route(`/foo/?`, #foo).matchUri(`/foo/`)
		verifyEq(match.size,	0)

		match = Route(`/foo*`, #foo).matchUri(`/foo`)
		verifyEq(match.size,	1)
		verifyEq(match[0],		null)
		
		match = Route(`/foo/*`, #foo).matchUri(`/foo`)
		verifyNull(match)

		match = Route(`/foo/*`, #foo).matchUri(`/foo/`)
		verifyEq(match.size,	1)
		verifyEq(match[0],		null)

		match = Route(`/foo/*/`, #foo).matchUri(`/foo//`)
		verifyEq(match.size,	1)
		verifyEq(match[0],		null)

		// case-insensitive
		match = Route(`/foo`, #foo).matchUri(`/fOO`)
		verifyEq(match.size,	0)

		match = Route(`/foobar/*/*`, #foo).matchUri(`/foobar/dude/3`)
		verifyEq(match.size,	2)
		verifyEq(match[0],		"dude")
		verifyEq(match[1],		"3")

		match = Route(`/foobar/*/*`, #foo).matchUri(`/foobar/dude`)
		verifyNull(match)

		match = Route(`/foobar/*/*`, #foo).matchUri(`/foobar/dude/2/3`)
		verifyNull(match)

		match = Route(`/foobar/***`, #foo)
		.matchUri(`/foobar/dude/2/3`)
		verifyEq(match.size,	1)
		verifyEq(match[0],		"dude/2/3")

		match = Route(`/foobar/**`, #foo).matchUri(`/foobar/dude/2/argh`)
		verifyEq(match.size,	3)
		verifyEq(match[0],		"dude")
		verifyEq(match[1],		"2")
		verifyEq(match[2],		"argh")

		match = Route(`/foobar/**`, #foo).matchUri(`/foobar/dude/2/argh/`)
		verifyEq(match.size,	3)
		verifyEq(match[0],		"dude")
		verifyEq(match[1],		"2")
		verifyEq(match[2],		"argh")
		
		match = Route(`/foobar**`, #foo).matchUri(`/foobarbitch/mf/`)
		verifyEq(match.size,	2)
		verifyEq(match[0],		"bitch")
		verifyEq(match[1],		"mf")
		
		match = Route(`/index`, #foo).matchUri(`/index?dude=3`)
		verifyEq(match.size,	0)
		
		match = Route(`/index/?`, #foo).matchUri(`/index?dude=3`)
		verifyEq(match.size,	0)

		match = Route(`/index*`, #foo).matchUri(`/index?dude=3`)
		verifyEq(match.size,	1)
		verifyEq(match[0],		null)

		match = Route(`/index**`, #foo).matchUri(`/index?dude=3`)
		verifyEq(match.size,	1)
		verifyEq(match[0],		null)

		match = Route(`/wot/*/ever/*`, #foo).matchUri(`/wot/3/ever/4`)
		verifyEq(match.size,	2)
		verifyEq(match[0],		"3")
		verifyEq(match[1],		"4")
	}
	
	// FIXME: route tests
//	Void testArgList() {
//		Str?[]? match
//		
//		// ---- handler1 ----
//		
//		match = Route(`/wotever/`, #handler1).matchArgs(Str[,])
//		verify(match.isEmpty)
//
//		match = Route(`/wotever/`, #handler1).matchArgs(["eek"])
//		verifyNull(match)
//		
//		// ---- handler2 ----
//
//		match = Route(`/wotever/`, #handler2).matchArgs(Str[,])
//		verifyNull(match)
//
//		match = Route(`/wotever/`, #handler2).matchArgs(["wot"])
//		verifyEq(match.size, 1)
//		verifyEq(match[0], "wot")
//
//		match = Route(`/wotever/`, #handler2).matchArgs(["wot", "ever"])
//		verifyNull(match)
//
//		// ---- handler3 ----
//
//		match = Route(`/wotever/`, #handler3).matchArgs(Str[,])
//		verifyNull(match)
//
//		match = Route(`/wotever/`, #handler3).matchArgs(["wot"])
//		verifyNull(match)
//
//		match = Route(`/wotever/`, #handler3).matchArgs(["wot", "ever"])
//		verifyEq(match.size, 2)
//		verifyEq(match[0], "wot")
//		verifyEq(match[1], "ever")
//		
//		match = Route(`/wotever/`, #handler3).matchArgs(["wot", "ever", "dude"])
//		verifyNull(match)
//
//		// ---- handler4 ----
//
//		match = Route(`/wotever/`, #handler4).matchArgs(Str[,])
//		verifyNull(match)
//
//		match = Route(`/wotever/`, #handler4).matchArgs(["wot"])
//		verifyEq(match.size, 1)
//		verifyEq(match[0], "wot")
//		
//		match = Route(`/wotever/`, #handler4).matchArgs(["wot", "ever"])
//		verifyEq(match.size, 2)
//		verifyEq(match[0], "wot")
//		verifyEq(match[1], "ever")
//		
//		match = Route(`/wotever/`, #handler4).matchArgs(["wot", "ever", "dude"])
//		verifyNull(match)
//
//		// ---- handler5 ----
//
//		match = Route(`/wotever/`, #handler5).matchArgs(Str[,])
//		verifyEq(match.size, 0)
//
//		match = Route(`/wotever/`, #handler5).matchArgs(["wot"])
//		verifyEq(match.size, 1)
//		verifyEq(match[0], "wot")
//		
//		match = Route(`/wotever/`, #handler5).matchArgs(["wot", "ever"])
//		verifyEq(match.size, 2)
//		verifyEq(match[0], "wot")
//		verifyEq(match[1], "ever")
//		
//		match = Route(`/wotever/`, #handler5).matchArgs(["wot", "ever", "dude"])
//		verifyNull(match)
//	}
//
//	Void testMatchArgsFromDocs() {
//		Str?[]? match
//
//		// Void bar1(Str a, Str b) { }
//		match = Route(`/`, #bar1).matchArgs(Str?[,])
//		verifyNull(match)
//		match = Route(`/`, #bar1).matchArgs(Str?[null])
//		verifyNull(match)
//		match = Route(`/`, #bar1).matchArgs(Str?[null, null])
//		verifyNull(match)
//		match = Route(`/`, #bar1).matchArgs(Str?["--", "--"])
//		verifyEq(match.size, 2)
//
//		// Void bar2(Str? a, Str? b) { }
//		match = Route(`/`, #bar2).matchArgs(Str?[,])
//		verifyNull(match)
//		match = Route(`/`, #bar2).matchArgs(Str?[null])
//		verifyNull(match)
//		match = Route(`/`, #bar2).matchArgs(Str?[null, null])
//		verifyEq(match.size, 2)
//		match = Route(`/`, #bar2).matchArgs(Str?["--", "--"])
//		verifyEq(match.size, 2)
//
//		// Void bar3(Str? a, Str? b := "") { }
//		match = Route(`/`, #bar3).matchArgs(Str?[,])
//		verifyNull(match)
//		match = Route(`/`, #bar3).matchArgs(Str?[null])
//		verifyEq(match.size, 1)
//		match = Route(`/`, #bar3).matchArgs(Str?[null, null])
//		verifyEq(match.size, 2)
//		match = Route(`/`, #bar3).matchArgs(Str?["--", "--"])
//		verifyEq(match.size, 2)
//
//		// Void bar4(Str? a, Str b := "") { }
//		match = Route(`/`, #bar4).matchArgs(Str?[,])
//		verifyNull(match)
//		match = Route(`/`, #bar4).matchArgs(Str?[null])
//		verifyEq(match.size, 1)
//		match = Route(`/`, #bar4).matchArgs(Str?[null, null])
//		verifyNull(match)
//		match = Route(`/`, #bar4).matchArgs(Str?["--", "--"])
//		verifyEq(match.size, 2)
//	}
//	
//	Void testFromModule() {
//		Str?[]? match
//
//		match = Route(`/route/optional/**`, #defaultParams).matchUri(`/route/optional/`)
//		verifyEq(match.size, 1)
//		verifyEq(match[0],	null)
//
//		match = Route(`/route/optional/**`, #defaultParams).matchArgs(match)
//		verifyEq(match.size, 1)
//		verifyEq(match[0],	null)
//	}
	
	Void defaultParams(Str? p1, Str p2 := "p2", Str p3 := "p3") { }
}
