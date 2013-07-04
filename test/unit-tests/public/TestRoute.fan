
internal class TestRoute : BsTest {
	
	Void foo() { }
	Void handler1() { }
	Void handler2(Str p1) { }
	Void handler3(Str p1, Int p2) { }
	Void handler4(Str p1, Int p2 := 69) { }
	Void handler5(Str? p1 := null, Obj p2 := 69) { }

	Void testUriPathOnly() {
		verifyBsErrMsg(BsMsgs.routeShouldBePathOnly(`http://www.alienfactory.co.uk/`)) {
			r := Route(`http://www.alienfactory.co.uk/`, #foo)
		}
	}

	Void testUriStartWithSlash() {
		verifyBsErrMsg(BsMsgs.routeShouldStartWithSlash(`foo/bar`)) {
			r := Route(`foo/bar`, #foo)
		}
	}	
	
	private Void dummyHandler(Uri uri) {}

	Void testHttpMethodMismatch() {
		match := Route(`/index`, #dummyHandler).match(`/index`, "POST")
		verifyNull(match)
	}
	
	Void testMatch() {
		Str[]? match
		
		match = Route(`/index`, #dummyHandler).matchUri(`/wotever`)
		verifyNull(match)
		
		match = Route(`/index`, #dummyHandler).matchUri(`/index`)
		verifyEq(match.size,	0)

		match = Route(`/foo/?`, #dummyHandler).matchUri(`/foo`)
		verifyEq(match.size,	0)

		match = Route(`/foo/?`, #dummyHandler).matchUri(`/foo/`)
		verifyEq(match.size,	0)

		match = Route(`/foo*`, #dummyHandler).matchUri(`/foo`)
		verifyEq(match.size,	1)
		verifyEq(match[0],		"")
		
		match = Route(`/foo/*`, #dummyHandler).matchUri(`/foo`)
		verifyNull(match)

		match = Route(`/foo/*`, #dummyHandler).matchUri(`/foo/`)
		verifyEq(match.size,	1)
		verifyEq(match[0],		"")

		match = Route(`/foo/*/`, #dummyHandler).matchUri(`/foo//`)
		verifyEq(match.size,	1)
		verifyEq(match[0],		"")

		// case-insensitive
		match = Route(`/foo`, #dummyHandler).matchUri(`/fOO`)
		verifyEq(match.size,	0)

		match = Route(`/foobar/*/*`, #dummyHandler).matchUri(`/foobar/dude/3`)
		verifyEq(match.size,	2)
		verifyEq(match[0],		"dude")
		verifyEq(match[1],		"3")

		match = Route(`/foobar/*/*`, #dummyHandler).matchUri(`/foobar/dude`)
		verifyNull(match)

		match = Route(`/foobar/*/*`, #dummyHandler).matchUri(`/foobar/dude/2/3`)
		verifyNull(match)

		match = Route(`/foobar/**`, #dummyHandler).matchUri(`/foobar/dude/2/argh`)
		verifyEq(match.size,	3)
		verifyEq(match[0],		"dude")
		verifyEq(match[1],		"2")
		verifyEq(match[2],		"argh")

		match = Route(`/foobar/**`, #dummyHandler).matchUri(`/foobar/dude/2/argh/`)
		verifyEq(match.size,	3)
		verifyEq(match[0],		"dude")
		verifyEq(match[1],		"2")
		verifyEq(match[2],		"argh")
		
		match = Route(`/foobar**`, #dummyHandler).matchUri(`/foobarbitch/mf/`)
		verifyEq(match.size,	2)
		verifyEq(match[0],		"bitch")
		verifyEq(match[1],		"mf")
		
		match = Route(`/index`, #dummyHandler).matchUri(`/index?dude=3`)
		verifyEq(match.size,	0)
		
		match = Route(`/index/?`, #dummyHandler).matchUri(`/index?dude=3`)
		verifyEq(match.size,	0)

		match = Route(`/index*`, #dummyHandler).matchUri(`/index?dude=3`)
		verifyEq(match.size,	1)
		verifyEq(match[0],		"")

		match = Route(`/index**`, #dummyHandler).matchUri(`/index?dude=3`)
		verifyEq(match.size,	1)
		verifyEq(match[0],		"")
	}
	
	Void testArgList() {
		Str[]? match
		
		// ---- handler1 ----
		
		match = Route(`/wotever/`, #handler1).matchArgs(Str[,])
		verify(match.isEmpty)

		match = Route(`/wotever/`, #handler1).matchArgs(["eek"])
		verifyNull(match)
		
		// ---- handler2 ----

		match = Route(`/wotever/`, #handler2).matchArgs(Str[,])
		verifyNull(match)

		match = Route(`/wotever/`, #handler2).matchArgs(["wot"])
		verifyEq(match.size, 1)
		verifyEq(match[0], "wot")

		match = Route(`/wotever/`, #handler2).matchArgs(["wot", "ever"])
		verifyNull(match)

		// ---- handler3 ----

		match = Route(`/wotever/`, #handler3).matchArgs(Str[,])
		verifyNull(match)

		match = Route(`/wotever/`, #handler3).matchArgs(["wot"])
		verifyNull(match)

		match = Route(`/wotever/`, #handler3).matchArgs(["wot", "ever"])
		verifyEq(match.size, 2)
		verifyEq(match[0], "wot")
		verifyEq(match[1], "ever")
		
		match = Route(`/wotever/`, #handler3).matchArgs(["wot", "ever", "dude"])
		verifyNull(match)

		// ---- handler4 ----

		match = Route(`/wotever/`, #handler4).matchArgs(Str[,])
		verifyNull(match)

		match = Route(`/wotever/`, #handler4).matchArgs(["wot"])
		verifyEq(match.size, 1)
		verifyEq(match[0], "wot")
		
		match = Route(`/wotever/`, #handler4).matchArgs(["wot", "ever"])
		verifyEq(match.size, 2)
		verifyEq(match[0], "wot")
		verifyEq(match[1], "ever")
		
		match = Route(`/wotever/`, #handler4).matchArgs(["wot", "ever", "dude"])
		verifyNull(match)

		// ---- handler5 ----

		match = Route(`/wotever/`, #handler5).matchArgs(Str[,])
		verifyEq(match.size, 0)

		match = Route(`/wotever/`, #handler5).matchArgs(["wot"])
		verifyEq(match.size, 1)
		verifyEq(match[0], "wot")
		
		match = Route(`/wotever/`, #handler5).matchArgs(["wot", "ever"])
		verifyEq(match.size, 2)
		verifyEq(match[0], "wot")
		verifyEq(match[1], "ever")
		
		match = Route(`/wotever/`, #handler5).matchArgs(["wot", "ever", "dude"])
		verifyNull(match)
	}
}