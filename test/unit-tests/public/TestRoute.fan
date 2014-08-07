
internal class TestRoute : BsTest {
	
	Void handler1() { }
	Void handler2(Str p1) { }
	Void handler3(Str p1, Int p2) { }
	Void handler4(Str p1, Int p2 := 69) { }
	Void handler5(Str? p1 := null, Obj p2 := 69) { }
	Void handler6(Str p1, Str p2, Int p3 := 69) { }
	
	Void bar1(Str a, Str b) { }
	Void bar2(Str? a, Str? b) { }
	Void bar3(Str? a, Str? b := "") { }
	Void bar4(Str? a, Str b := "") { }

	Void testUriPathOnly() {
		verifyErrMsg(ArgErr#, BsErrMsgs.route_shouldBePathOnly(`http://www.alienfactory.co.uk/`)) {
			r := Route(`http://www.alienfactory.co.uk/`, #handler1)
		}
	}

	Void testUriStartWithSlash() {
		verifyErrMsg(ArgErr#, BsErrMsgs.route_shouldStartWithSlash(`foo/bar`)) {
			r := Route(`foo/bar`, #handler1)
		}
	}	

	Void testHttpMethodMismatch() {
		match := Route(`/index`, #handler1).match(`/index`, "POST")
		verifyNull(match)
	}
	
	Void testMatchRegex() {
		Str?[]? match
		
		match = Route(Regex<|(?i)^\/index$|>, #handler1).matchUri(`/index`)
		verifyEq(match.size,	0)

		match = Route(Regex<|(?i)^\/index\/(.*?)$|>, #handler2).matchUri(`/index/dude`)
		verifyEq(match.size,	1)
		verifyEq(match[0],		"dude")
		
		match = Route(Regex<|(?i)^\/foobar\/(.*?)$|>, #handler2, "GET", true)
		.matchUri(`/foobar/dude/2/argh`)
		verifyEq(match.size,	3)
		verifyEq(match[0],		"dude")
		verifyEq(match[1],		"2")
		verifyEq(match[2],		"argh")
	}
	
	Void testMatchGlobFromDocs() {
		Str?[]? match

		match = Route(`/user/*`, #handler2).matchUri(`/user/`)
		verifyEq(match.size,	1)
		verifyEq(match[0],		null)
		match = Route(`/user/*`, #handler2).matchUri(`/user/42`)
		verifyEq(match.size,	1)
		verifyEq(match[0],		"42")
		match = Route(`/user/*`, #handler2).matchUri(`/user/42/`)
		verifyNull(match)
		match = Route(`/user/*`, #handler2).matchUri(`/user/42/dee`)
		verifyNull(match)

		match = Route(`/user/*/*`, #handler3).matchUri(`/user/`)
		verifyNull(match)
		match = Route(`/user/*/*`, #handler3).matchUri(`/user/42`)
		verifyNull(match)
		match = Route(`/user/*/*`, #handler3).matchUri(`/user/42/`)
		verifyEq(match.size,	2)
		verifyEq(match[0],		"42")
		verifyEq(match[1],		null)
		match = Route(`/user/*/*`, #handler3).matchUri(`/user/42/dee`)
		verifyEq(match.size,	2)
		verifyEq(match[0],		"42")
		verifyEq(match[1],		"dee")

		match = Route(`/user/**`, #handler2).matchUri(`/user/`)
		verifyEq(match.size,	1)
		verifyEq(match[0],		null)
		match = Route(`/user/**`, #handler2).matchUri(`/user/42`)
		verifyEq(match.size,	1)
		verifyEq(match[0],		"42")
		match = Route(`/user/**`, #handler2).matchUri(`/user/42/`)
		verifyEq(match.size,	1)
		verifyEq(match[0],		"42")
		match = Route(`/user/**`, #handler2).matchUri(`/user/42/dee`)
		verifyEq(match.size,	2)
		verifyEq(match[0],		"42")
		verifyEq(match[1],		"dee")

		match = Route(`/user/***`, #handler2).matchUri(`/user/`)
		verifyEq(match.size,	1)
		verifyEq(match[0],		null)
		match = Route(`/user/***`, #handler2).matchUri(`/user/42`)
		verifyEq(match.size,	1)
		verifyEq(match[0],		"42")
		match = Route(`/user/***`, #handler2).matchUri(`/user/42/`)
		verifyEq(match.size,	1)
		verifyEq(match[0],		"42/")
		match = Route(`/user/***`, #handler2).matchUri(`/user/42/dee`)
		verifyEq(match.size,	1)
		verifyEq(match[0],		"42/dee")
	}

	Void testMatchGlob() {
		Str?[]? match
		
		match = Route(`/index`, #handler1).matchUri(`/wotever`)
		verifyNull(match)
		
		match = Route(`/index`, #handler1).matchUri(`/index`)
		verifyEq(match.size,	0)

		match = Route(`/foo/?`, #handler1).matchUri(`/foo`)
		verifyEq(match.size,	0)

		match = Route(`/foo/?`, #handler1).matchUri(`/foo/`)
		verifyEq(match.size,	0)

		match = Route(`/foo*`, #handler2).matchUri(`/foo`)
		verifyEq(match.size,	1)
		verifyEq(match[0],		null)
		
		match = Route(`/foo/*`, #handler2).matchUri(`/foo`)
		verifyNull(match)

		match = Route(`/foo/*`, #handler2).matchUri(`/foo/`)
		verifyEq(match.size,	1)
		verifyEq(match[0],		null)

		match = Route(`/foo/*/`, #handler2).matchUri(`/foo//`)
		verifyEq(match.size,	1)
		verifyEq(match[0],		null)

		// case-insensitive
		match = Route(`/foo`,	#handler1).matchUri(`/fOO`)
		verifyEq(match.size,	0)

		match = Route(`/foobar/*/*`, #handler3).matchUri(`/foobar/dude/3`)
		verifyEq(match.size,	2)
		verifyEq(match[0],		"dude")
		verifyEq(match[1],		"3")

		match = Route(`/foobar/*/*`, #handler3).matchUri(`/foobar/dude`)
		verifyNull(match)

		match = Route(`/foobar/*/*`, #handler3).matchUri(`/foobar/dude/2/3`)
		verifyNull(match)

		match = Route(`/foobar/***`, #handler2)
		.matchUri(`/foobar/dude/2/3`)
		verifyEq(match.size,	1)
		verifyEq(match[0],		"dude/2/3")

		match = Route(`/foobar/**`, #handler2).matchUri(`/foobar/dude/2/argh`)
		verifyEq(match.size,	3)
		verifyEq(match[0],		"dude")
		verifyEq(match[1],		"2")
		verifyEq(match[2],		"argh")

		match = Route(`/foobar/**`, #handler2).matchUri(`/foobar/dude/2/argh/`)
		verifyEq(match.size,	3)
		verifyEq(match[0],		"dude")
		verifyEq(match[1],		"2")
		verifyEq(match[2],		"argh")
		
		match = Route(`/foobar**`, #handler2).matchUri(`/foobarbitch/mf/`)
		verifyEq(match.size,	2)
		verifyEq(match[0],		"bitch")
		verifyEq(match[1],		"mf")
		
		match = Route(`/index`, #handler1).matchUri(`/index?dude=3`)
		verifyEq(match.size,	0)
		
		match = Route(`/index/?`, #handler1).matchUri(`/index?dude=3`)
		verifyEq(match.size,	0)

		match = Route(`/index*`, #handler2).matchUri(`/index?dude=3`)
		verifyEq(match.size,	1)
		verifyEq(match[0],		null)

		match = Route(`/index**`, #handler2).matchUri(`/index?dude=3`)
		verifyEq(match.size,	1)
		verifyEq(match[0],		null)

		match = Route(`/wot/*/ever/*`, #handler3).matchUri(`/wot/3/ever/4`)
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

	Void testMethodValidation() {
		verifyErrMsg(ArgErr#, BsErrMsgs.route_uriWillNeverMatchMethod("".toRegex, `/route/***`, #handler1)) {
			r := Route(`/route/***`, #handler1)
		}
		verifyErrMsg(ArgErr#, BsErrMsgs.route_uriWillNeverMatchMethod("".toRegex, `/route/**`,  #handler1)) {
			r := Route(`/route/**`,  #handler1)
		}
		verifyErrMsg(ArgErr#, BsErrMsgs.route_uriWillNeverMatchMethod("".toRegex, `/route/*`,   #handler1)) {
			r := Route(`/route/*`,   #handler1)
		}
		verifyErrMsg(ArgErr#, BsErrMsgs.route_uriWillNeverMatchMethod("".toRegex, `/route/*/***`, #handler2)) {
			r := Route(`/route/*/***`, #handler2)
		}
		verifyErrMsg(ArgErr#, BsErrMsgs.route_uriWillNeverMatchMethod("".toRegex, `/route/*/**`,  #handler2)) {
			r := Route(`/route/*/**`,  #handler2)
		}
		verifyErrMsg(ArgErr#, BsErrMsgs.route_uriWillNeverMatchMethod("".toRegex, `/route/*/*`,   #handler2)) {
			r := Route(`/route/*/*`,   #handler2)
		}
		
		verifyErrMsg(ArgErr#, BsErrMsgs.route_uriWillNeverMatchMethod("".toRegex, `/route/*`, #handler6)) {
			r := Route(`/route/*`,   #handler6)
		}
		
		// these are allowed!
		r := Route(`/route/*/*`,  #handler6)
		r  = Route(`/route/**`,   #handler6)
	}
	
	Void defaultParams(Str? p1, Str p2 := "p2", Str p3 := "p3") { }
}
