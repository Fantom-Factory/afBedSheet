
internal class TestArgRoute : BsTest {

	Void foo() { }
	Void handler1() { }
	Void handler2(Str p1) { }
	Void handler3(Str p1, Int p2) { }
	Void handler4(Str p1, Int p2 := 69) { }
	Void handler5(Str? p1 := null, Obj p2 := 69) { }
	
	Void testUriPathOnly() {
		verifyBsErrMsg(BsMsgs.routeShouldBePathOnly(`http://www.alienfactory.co.uk/`)) {
			r := ArgRoute(`http://www.alienfactory.co.uk/`, #foo)
		}

		verifyBsErrMsg(BsMsgs.routeShouldBePathOnly(`/foo/bar?kick=ass`)) {
			r := ArgRoute(`/foo/bar?kick=ass`, #foo)
		}
	}

	Void testUriStartWithSlash() {
		verifyBsErrMsg(BsMsgs.routeShouldStartWithSlash(`foo/bar`)) {
			r := ArgRoute(`foo/bar`, #foo)
		}
	}	
	
	Void testArgList() {
		ArgRoute? rm := null
		
		// ---- handler1 ----
		
		rm = ArgRoute(`/wotever/`, #handler1)
		verify(rm.argList(``).isEmpty)

		verifyRouteNotFoundErrMsg(BsMsgs.handlerArgSizeMismatch(#handler1, `eek`)) {
			ArgRoute(`/wotever/`, #handler1).argList(`eek`)
		}
		
		// ---- handler2 ----

		verifyRouteNotFoundErrMsg(BsMsgs.handlerArgSizeMismatch(#handler2, ``)) {
			ArgRoute(`/wotever/`, #handler2).argList(``)
		}

		rm = ArgRoute(`/wotever/`, #handler2)
		verifyEq(rm.argList(`wot`).size, 1)
		verifyEq(rm.argList(`wot`)[0], "wot")

		verifyRouteNotFoundErrMsg(BsMsgs.handlerArgSizeMismatch(#handler2, `wot/ever`)) {
			ArgRoute(`/wotever/`, #handler2).argList(`wot/ever`)
		}

		// ---- handler3 ----

		verifyRouteNotFoundErrMsg(BsMsgs.handlerArgSizeMismatch(#handler3, ``)) {
			ArgRoute(`/wotever/`, #handler3).argList(``)
		}

		verifyRouteNotFoundErrMsg(BsMsgs.handlerArgSizeMismatch(#handler3, `wot`)) {
			ArgRoute(`/wotever/`, #handler3).argList(`wot`)
		}

		rm = ArgRoute(`/wotever/`, #handler3)
		verifyEq(rm.argList(`wot/ever`).size, 2)
		verifyEq(rm.argList(`wot/ever`)[0], "wot")
		verifyEq(rm.argList(`wot/ever`)[1], "ever")
		
		verifyRouteNotFoundErrMsg(BsMsgs.handlerArgSizeMismatch(#handler3, `wot/ever/dude`)) {
			ArgRoute(`/wotever/`, #handler3).argList(`wot/ever/dude`)
		}

		// ---- handler4 ----

		verifyRouteNotFoundErrMsg(BsMsgs.handlerArgSizeMismatch(#handler4, ``)) {
			ArgRoute(`/wotever/`, #handler4).argList(``)
		}

		rm = ArgRoute(`/wotever/`, #handler4)
		verifyEq(rm.argList(`wot`).size, 1)
		verifyEq(rm.argList(`wot`)[0], "wot")
		
		rm = ArgRoute(`/wotever/`, #handler4)
		verifyEq(rm.argList(`wot/ever`).size, 2)
		verifyEq(rm.argList(`wot/ever`)[0], "wot")
		verifyEq(rm.argList(`wot/ever`)[1], "ever")
		
		verifyRouteNotFoundErrMsg(BsMsgs.handlerArgSizeMismatch(#handler4, `wot/ever/dude`)) {
			ArgRoute(`/wotever/`, #handler4).argList(`wot/ever/dude`)
		}

		// ---- handler5 ----

		rm = ArgRoute(`/wotever/`,  #handler5)
		verifyEq(rm.argList(``).size, 0)

		rm = ArgRoute(`/wotever/`, #handler5)
		verifyEq(rm.argList(`wot`).size, 1)
		verifyEq(rm.argList(`wot`)[0], "wot")
		
		rm = ArgRoute(`/wotever/`, #handler5)
		verifyEq(rm.argList(`wot/ever`).size, 2)
		verifyEq(rm.argList(`wot/ever`)[0], "wot")
		verifyEq(rm.argList(`wot/ever`)[1], "ever")
		
		verifyRouteNotFoundErrMsg(BsMsgs.handlerArgSizeMismatch(#handler5, `wot/ever/dude`)) {
			ArgRoute(`/wotever/`, #handler5).argList(`wot/ever/dude`)
		}
	}
}
