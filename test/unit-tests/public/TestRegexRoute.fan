
internal class TestRegexRoute : BsTest {
	
//	Void testBuggy() {
//		Str?[]? match
//		
//		// this test shows that we've overstretched the limites of Regexs!
//		// was trying to do some fancy page event handling
//		
//		match = RegexRoute("(?i)^\\/package\\/(.*)\\/edit\\/(.*)\\/?(.*)\$".toRegex, #handlerBug).matchUri(`/package/fin5Ext/edit/addPkgTag`)
//		verifyEq(match.size,	2)
//		verifyEq(match[0],		"fin5Ext")
//		verifyEq(match[1],		"addPkgTag")
//	}
	
	Void handlerBug(Str event, Str? extra := null) { }
	
	Void handler1() { }
	Void handler2(Str p1) { }
	Void handler3(Str p1, Int p2) { }
	Void handler4(Str p1, Int p2 := 69) { }
	Void handler5(Str? p1 := null, Obj p2 := 69) { }
	Void handler6(Str p1, Str p2, Int p3 := 69) { }
	Void handler7(Str? p1 := "wotever") { }

	Void objHandler2(Obj? p1) { }
	
	Void bar1(Str a, Str b) { }
	Void bar2(Str? a, Str? b) { }
	Void bar3(Str? a, Str? b := "") { }
	Void bar4(Str? a, Str b := "") { }

	Void stackhubOrg(Str org, Str? pageUrl := null) { }

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
		httpReq := T_HttpRequest { it.httpMethod = "POST"; it.url = `/index` }
		match := Route(`/index`, #handler1).match(httpReq)
		verifyNull(match)

		// test case-insensitive match
		match = Route(`/index`, #handler1, "post").match(httpReq)
		verifyNotNull(match)
	}

	Void testNonNullableWithDefault() {
		// tests from pillow
		httpReq := T_HttpRequest { it.url = `/index` }
		match := (MethodCall?) Route(`/index/**`, #handler7).match(httpReq)
		verifyNull(match)

		match = (MethodCall) Route(`/index/?**`, #handler7).match(httpReq)
		verify(match.args.isEmpty)
	}

	Void testUriDecoding() {
		// lots of whitebox testing, trying to catch out the internals of RegexRoute
		route   := Route(`/meep/**`, #handler3)

		httpReq := T_HttpRequest { it.url = `/meep/-\/-/..\@..` }
		match	:= (MethodCall?) route.match(httpReq)
		verifyEq(match?.args[0], "-/-")
		verifyEq(match?.args[1], "..@..")
		
		httpReq = T_HttpRequest { it.url = `/meep/--\\\\/..\@..` }
		match	= (MethodCall?) route.match(httpReq)
		verifyEq(match?.args[0], "--\\\\")
		verifyEq(match?.args[1], "..@..")

		route   = Route(`/meep/*`, #handler2)
		httpReq = T_HttpRequest { it.url = `/meep/-\/-` }
		match	= (MethodCall?) route.match(httpReq)
		verifyEq(match?.args[0], "-/-")

		route   = Route(`/meep/*`, #handler2)
		httpReq = T_HttpRequest { it.url = `/meep/-\/-/-` }
		match	= (MethodCall?) route.match(httpReq)
		verifyNull(match)

		route   = Route(`/meep/me\/ep/*`, #handler2)
		httpReq = T_HttpRequest { it.url = `/meep/me\/ep/foo` }
		match	= (MethodCall?) route.match(httpReq)
		verifyEq(match?.args[0], "foo")

		// test unicode - using a radioactive symbol!
		route   = Route(`/meep/me\u2622ep/*`, #handler2)
		httpReq = T_HttpRequest { it.url = `/meep/me\u2622ep/foo` }
		match	= (MethodCall?) route.match(httpReq)
		verifyEq(match?.args[0], "foo")
	}

	Void testNonMethodMatch() {
		route := Route(`/greet.*`, 69)
		
		httpReq := T_HttpRequest { it.url = `/greet.html` }
		verifyEq(69, route.match(httpReq))

		httpReq = T_HttpRequest { it.url = `/greet.php` }
		verifyEq(69, route.match(httpReq))

		httpReq = T_HttpRequest { it.url = `/greet` }
		verifyNull(route.match(httpReq))
	}
	
	Void testMatchRegex() {
		Str?[]? match
		
		match = RegexRoute(Regex<|(?i)^\/index$|>, #handler1).matchUri(`/index`)
		verifyEq(match.size,	0)

		match = RegexRoute(Regex<|(?i)^\/index\/(.*?)$|>, #handler2).matchUri(`/index/dude`)
		verifyEq(match.size,	1)
		verifyEq(match[0],		"dude")
		
		match = RegexRoute(Regex<|(?i)^\/foobar\/(.*?)$|>, #handler2, "GET", true).matchUri(`/foobar/dude/2/argh`)
		verifyEq(match.size,	3)
		verifyEq(match[0],		"dude")
		verifyEq(match[1],		"2")
		verifyEq(match[2],		"argh")

		// FIXME Regex limitation (yeah - I got 2 problems!)
		match = RegexRoute(Regex<|(?i)^\/org\/(.*?)\/?(.*?)$|>, #stackhubOrg, "GET", true).matchUri(`/org/StackHub`)
		verifyEq(match.size,	2)
		verifyEq(match[0],		null)		// :( should be null
		verifyEq(match[1],		"StackHub")	// :( should be "StackHub"
	}
	
	Void testMatchGlobFromDocs() {
		Str?[]? match

		match = RegexRoute(`/user/*`, #handler2).matchUri(`/user/`)
		verifyEq(match.size,	1)
		verifyEq(match[0],		null)
		match = RegexRoute(`/user/*`, #handler2).matchUri(`/user/42`)
		verifyEq(match.size,	1)
		verifyEq(match[0],		"42")
		match = RegexRoute(`/user/*`, #handler2).matchUri(`/user/42/`)
		verifyNull(match)
		match = RegexRoute(`/user/*`, #handler2).matchUri(`/user/42/dee`)
		verifyNull(match)

		match = RegexRoute(`/user/*/*`, #handler3).matchUri(`/user/`)
		verifyNull(match)
		match = RegexRoute(`/user/*/*`, #handler3).matchUri(`/user/42`)
		verifyNull(match)
		match = RegexRoute(`/user/*/*`, #handler3).matchUri(`/user/42/`)
		verifyEq(match.size,	2)
		verifyEq(match[0],		"42")
		verifyEq(match[1],		null)
		match = RegexRoute(`/user/*/*`, #handler3).matchUri(`/user/42/dee`)
		verifyEq(match.size,	2)
		verifyEq(match[0],		"42")
		verifyEq(match[1],		"dee")

		match = RegexRoute(`/user/**`, #handler2).matchUri(`/user/`)
		verifyEq(match.size,	1)
		verifyEq(match[0],		null)
		match = RegexRoute(`/user/**`, #handler2).matchUri(`/user/42`)
		verifyEq(match.size,	1)
		verifyEq(match[0],		"42")
		match = RegexRoute(`/user/**`, #handler2).matchUri(`/user/42/`)
		verifyEq(match.size,	2)
		verifyEq(match[0],		"42")
		verifyEq(match[1],		null)
		match = RegexRoute(`/user/**`, #handler2).matchUri(`/user/42/dee`)
		verifyEq(match.size,	2)
		verifyEq(match[0],		"42")
		verifyEq(match[1],		"dee")

		match = RegexRoute(`/user/***`, #handler2).matchUri(`/user/`)
		verifyEq(match.size,	1)
		verifyEq(match[0],		null)
		match = RegexRoute(`/user/***`, #handler2).matchUri(`/user/42`)
		verifyEq(match.size,	1)
		verifyEq(match[0],		"42")
		match = RegexRoute(`/user/***`, #handler2).matchUri(`/user/42/`)
		verifyEq(match.size,	1)
		verifyEq(match[0],		"42/")
		match = RegexRoute(`/user/***`, #handler2).matchUri(`/user/42/dee`)
		verifyEq(match.size,	1)
		verifyEq(match[0],		"42/dee")
	}

	Void docMethod1(Obj p1, Obj p2) { }

	
	Void testMatchGlob() {
		Str?[]? match
		
		match = RegexRoute(`/index`, #handler1).matchUri(`/wotever`)
		verifyNull(match)
		
		match = RegexRoute(`/index`, #handler1).matchUri(`/index`)
		verifyEq(match.size,	0)

		match = RegexRoute(`/foo/?`, #handler1).matchUri(`/foo`)
		verifyEq(match.size,	0)

		match = RegexRoute(`/foo/?`, #handler1).matchUri(`/foo/`)
		verifyEq(match.size,	0)

		match = RegexRoute(`/foo*`, #handler2).matchUri(`/foo`)
		verifyEq(match.size,	0)
		
		match = RegexRoute(`/foo/*`, #handler2).matchUri(`/foo`)
		verifyNull(match)

		match = matchRoute(`/foo/*`, #handler2, `/foo/`)
		verifyEq(match.size,	1)
		verifyEq(match[0],		"")
		match = matchRoute(`/foo/*`, #objHandler2, `/foo/`)
		verifyEq(match.size,	1)
		verifyEq(match[0],		null)

		match = RegexRoute(`/foo/*/`, #handler2).matchUri(`/foo//`)
		verifyEq(match.size,	1)
		verifyEq(match[0],		null)

		// case-insensitive
		match = RegexRoute(`/foo`,	#handler1).matchUri(`/fOO`)
		verifyEq(match.size,	0)

		match = RegexRoute(`/foobar/*/*`, #handler3).matchUri(`/foobar/dude/3`)
		verifyEq(match.size,	2)
		verifyEq(match[0],		"dude")
		verifyEq(match[1],		"3")

		match = RegexRoute(`/foobar/*/*`, #handler3).matchUri(`/foobar/dude`)
		verifyNull(match)

		match = RegexRoute(`/foobar/*/*`, #handler3).matchUri(`/foobar/dude/2/3`)
		verifyNull(match)

		match = RegexRoute(`/foobar/***`, #handler2)
		.matchUri(`/foobar/dude/2/3`)
		verifyEq(match.size,	1)
		verifyEq(match[0],		"dude/2/3")

		match = RegexRoute(`/foobar/**`, #handler2).matchUri(`/foobar/dude/2/argh`)
		verifyEq(match.size,	3)
		verifyEq(match[0],		"dude")
		verifyEq(match[1],		"2")
		verifyEq(match[2],		"argh")

		match = RegexRoute(`/foobar/**`, #handler2).matchUri(`/foobar/dude/2/argh/`)
		verifyEq(match.size,	4)
		verifyEq(match[0],		"dude")
		verifyEq(match[1],		"2")
		verifyEq(match[2],		"argh")
		verifyEq(match[3],		null)
		
		match = RegexRoute(`/foobar**`, #handler2).matchUri(`/foobarbitch/mf/`)
		verifyEq(match.size,	3)
		verifyEq(match[0],		"bitch")
		verifyEq(match[1],		"mf")
		verifyEq(match[2],		null)
		
		match = RegexRoute(`/index`, #handler1).matchUri(`/index?dude=3`)
		verifyEq(match.size,	0)
		
		match = RegexRoute(`/index/?`, #handler1).matchUri(`/index?dude=3`)
		verifyEq(match.size,	0)

		match = RegexRoute(`/index*`, #handler2).matchUri(`/index?dude=3`)
		verifyEq(match.size,	0)

		match = RegexRoute(`/index**`, #handler2).matchUri(`/index?dude=3`)
		verifyEq(match.size,	0)

		match = RegexRoute(`/wot/*/ever/*`, #handler3).matchUri(`/wot/3/ever/4`)
		verifyEq(match.size,	2)
		verifyEq(match[0],		"3")
		verifyEq(match[1],		"4")
	}
	
	Void testParamsFromDocs() {
		Obj?[]? match
		
		match = matchParams([null], #doc2)
		verifyEq(match.size,	1)
		verifyEq(match[0],		null)
		
		match = matchParams([""], #doc2)
		verifyEq(match.size,	1)
		verifyEq(match[0],		null)

		match = matchParams([""], #doc3)
		verifyEq(match.size,	1)
		verifyEq(match[0],		"")

		match = matchParams(["wotever"], #doc3)
		verifyEq(match.size,	1)
		verifyEq(match[0],		"wotever")

		match = matchParams([""], #doc4)
		verifyEq(match.size,	1)
		verifyEq(match[0],		null)

		match = matchParams([null], #doc5)
		verifyEq(match.size,	1)
		verifyEq(match[0],		0)

		match = matchParams([""], #doc5)
		verifyEq(match.size,	1)
		verifyEq(match[0],		0)

		match = matchParams(["68"], #doc5)
		verifyEq(match.size,	1)
		verifyEq(match[0],		68)

		match = matchParams(["wotever"], #doc5)
		verifyNull(match)

		match = matchParams([null], #doc6)
		verifyEq(match.size,	1)
		verifyEq(match[0],		null)

		match = matchParams([""], #doc7)
		verifyEq(match.size,	1)
		verifyEq(match[0],		"")
	}
	
	Void doc2(Str? a) {}
	Void doc3(Str a) {}
	Void doc4(Int? a) {}
	Void doc5(Int a) {}
	Void doc6(Str? a, Int b := 68) {}
	Void doc7(Str a, Int b := 68) {}
	
	ValueEncoders valueEncoders := ValueEncodersImpl([:])
	Obj?[] matchRoute(Uri regex, Method method, Uri req) {
		httpReq := T_HttpRequest { it.url = req }
		mCall := (MethodCall?) RegexRoute(regex, method).match(httpReq)
		return mCall == null ? Obj#.emptyList : matchParams(mCall.args, method)
	}
	Obj?[]? matchParams(Obj?[] strs, Method method) {
		
		// copied from RouteResponseFactory
		method.params.each |Param param, i| {
			if (i >= strs.size)
				return
			if (strs[i] == null && !param.type.isNullable) {
				// convert nulls to "" and let the valueEncoder convert
				strs[i] = ""
			}			
		}

		// copied from MethodCallProcessor
		try {
			args := strs.map |arg, i -> Obj?| {
				paramType	:= method.params.getSafe(i)?.type
				if (paramType == null)
					return arg
				return arg is Str ? valueEncoders.toValue(paramType, arg) : arg
			}
			return args			
		} catch (ValueEncodingErr err)
			return null
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
		verifyTrue(match)
		match = MethodCallFactory(#bar1).matchSegments(Str?["--", "--"])
		verifyTrue(match)

		// Void bar2(Str? a, Str? b) { }
		match = MethodCallFactory(#bar2).matchSegments(Str?[,])
		verifyFalse(match)
		match = MethodCallFactory(#bar2).matchSegments(Str?[null])
		verifyFalse(match)
		match = MethodCallFactory(#bar2).matchSegments(Str?[null, null])
		verifyTrue(match)
		match = MethodCallFactory(#bar2).matchSegments(Str?["--", "--"])
		verifyTrue(match)

		// Void bar3(Str? a, Str? b := "") { }
		match = MethodCallFactory(#bar3).matchSegments(Str?[,])
		verifyFalse(match)
		match = MethodCallFactory(#bar3).matchSegments(Str?[null])
		verifyTrue(match)
		match = MethodCallFactory(#bar3).matchSegments(Str?[null, null])
		verifyTrue(match)
		match = MethodCallFactory(#bar3).matchSegments(Str?["--", "--"])
		verifyTrue(match)

		// Void bar4(Str? a, Str b := "") { }
		match = MethodCallFactory(#bar4).matchSegments(Str?[,])
		verifyFalse(match)
		match = MethodCallFactory(#bar4).matchSegments(Str?[null])
		verifyTrue(match)
		match = MethodCallFactory(#bar4).matchSegments(Str?[null, null])
		verifyTrue(match)
		match = MethodCallFactory(#bar4).matchSegments(Str?["--", "--"])
		verifyTrue(match)
	}
	
	Void testFromModule() {
		Str?[]? match

		match = matchRoute(`/route/optional/**`, #wotever, `/route/optional//`)
		verifyEq(match.size, 2)
		verifyEq(match[0],	null)

		match = matchRoute(`/route/optional/*`, #defaultParams, `/route/optional/`)
		verifyEq(match.size, 1)
		verifyEq(match[0],	null)

		match = matchRoute(`/route/optional/**`, #defaultParams, `/route/optional/`)
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
	Void wotever(Str? p1, Str? p2) { }
}

internal const class T_HttpRequest : HttpRequestImpl {
	override const Str httpMethod := "GET"
	override const Uri url
	new make(|This|in) : super(in) {
		in(this)
	}
}
