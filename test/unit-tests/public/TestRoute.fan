
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
	
	Void testArgList() {
		Bool match
		
		// ---- handler1 ----
		
		match = MethodCallFactory(#handler1).matchSegments(Str[,])
		verify(match)
			
		match = MethodCallFactory(#handler1).matchSegments(["eek"])
		verifyFalse(match)
		
		// ---- handler2 ----

		match = MethodCallFactory(#handler2).matchSegments(Str[,])
		verifyFalse(match)

		match = MethodCallFactory(#handler2).matchSegments(["wot"])
		verify(match)

		match = MethodCallFactory(#handler2).matchSegments(["wot", "ever"])
		verifyFalse(match)

		// ---- handler3 ----

		match = MethodCallFactory(#handler3).matchSegments(Str[,])
		verifyFalse(match)

		match = MethodCallFactory(#handler3).matchSegments(["wot"])
		verifyFalse(match)

		match = MethodCallFactory(#handler3).matchSegments(["wot", "ever"])
		verify(match)
		
		match = MethodCallFactory(#handler3).matchSegments(["wot", "ever", "dude"])
		verifyFalse(match)

		// ---- handler4 ----

		match = MethodCallFactory(#handler4).matchSegments(Str[,])
		verifyFalse(match)

		match = MethodCallFactory(#handler4).matchSegments(["wot"])
		verify(match)
		
		match = MethodCallFactory(#handler4).matchSegments(["wot", "ever"])
		verify(match)
		
		match = MethodCallFactory(#handler4).matchSegments(["wot", "ever", "dude"])
		verifyFalse(match)

		// ---- handler5 ----

		match = MethodCallFactory(#handler5).matchSegments(Str[,])
		verify(match)

		match = MethodCallFactory(#handler5).matchSegments(["wot"])
		verify(match)
		
		match = MethodCallFactory(#handler5).matchSegments(["wot", "ever"])
		verify(match)
		
		match = MethodCallFactory(#handler5).matchSegments(["wot", "ever", "dude"])
		verifyFalse(match)
	}

	Void testMatchArgsFromDocs() {
		Bool? match

		// Void bar1(Str a, Str b) { }
		match = MethodCallFactory(#bar1).matchSegments(Str?[,])
		verifyFalse(match)
		match = MethodCallFactory(#bar1).matchSegments(Str?[null])
		verifyFalse(match)
		match = MethodCallFactory(#bar1).matchSegments(Str?[null, null])
		verifyFalse(match)
		match = MethodCallFactory(#bar1).matchSegments(Str?["--", "--"])
		verify(match)

		// Void bar2(Str? a, Str? b) { }
		match = MethodCallFactory(#bar2).matchSegments(Str?[,])
		verifyFalse(match)
		match = MethodCallFactory(#bar2).matchSegments(Str?[null])
		verifyFalse(match)
		match = MethodCallFactory(#bar2).matchSegments(Str?[null, null])
		verify(match)
		match = MethodCallFactory(#bar2).matchSegments(Str?["--", "--"])
		verify(match)

		// Void bar3(Str? a, Str? b := "") { }
		match = MethodCallFactory(#bar3).matchSegments(Str?[,])
		verifyFalse(match)
		match = MethodCallFactory(#bar3).matchSegments(Str?[null])
		verify(match)
		match = MethodCallFactory(#bar3).matchSegments(Str?[null, null])
		verify(match)
		match = MethodCallFactory(#bar3).matchSegments(Str?["--", "--"])
		verify(match)

		// Void bar4(Str? a, Str b := "") { }
		match = MethodCallFactory(#bar4).matchSegments(Str?[,])
		verifyFalse(match)
		match = MethodCallFactory(#bar4).matchSegments(Str?[null])
		verify(match)
		match = MethodCallFactory(#bar4).matchSegments(Str?[null, null])
		verifyFalse(match)
		match = MethodCallFactory(#bar4).matchSegments(Str?["--", "--"])
		verify(match)
	}
	
	Void testFromModule() {
		Str?[]? match

		match = Route(`/route/optional/**`, #defaultParams).matchUri(`/route/optional/`)
		verifyEq(match.size, 1)
		verifyEq(match[0],	null)
	}
	
	Void defaultParams(Str? p1, Str p2 := "p2", Str p3 := "p3") { }
}
