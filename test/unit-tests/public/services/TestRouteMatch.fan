
internal class TestRouteMatch : BsTest {
	
	Void handler1() { }
	Void handler2(Str p1) { }
	Void handler3(Str p1, Int p2) { }
	Void handler4(Str p1, Int p2 := 69) { }
	Void handler5(Str? p1 := null, Obj p2 := 69) { }
	
	Void testArgList() {
		RouteMatch? rm := null
		
		// ---- handler1 ----
		
		rm = RouteMatch(`/wotever/`, ``, #handler1)
		verify(rm.argList.isEmpty)

		verifyRouteNotFoundErrMsg(BsMsgs.handlerArgSizeMismatch(#handler1, `eek`)) {
			RouteMatch(`/wotever/`, `eek`, #handler1).argList
		}
		
		// ---- handler2 ----

		verifyRouteNotFoundErrMsg(BsMsgs.handlerArgSizeMismatch(#handler2, ``)) {
			RouteMatch(`/wotever/`, ``, #handler2).argList
		}

		rm = RouteMatch(`/wotever/`, `wot`, #handler2)
		verifyEq(rm.argList.size, 1)
		verifyEq(rm.argList[0], "wot")

		verifyRouteNotFoundErrMsg(BsMsgs.handlerArgSizeMismatch(#handler2, `wot/ever`)) {
			RouteMatch(`/wotever/`, `wot/ever`, #handler2).argList
		}

		// ---- handler3 ----

		verifyRouteNotFoundErrMsg(BsMsgs.handlerArgSizeMismatch(#handler3, ``)) {
			RouteMatch(`/wotever/`, ``, #handler3).argList
		}

		verifyRouteNotFoundErrMsg(BsMsgs.handlerArgSizeMismatch(#handler3, `wot`)) {
			RouteMatch(`/wotever/`, `wot`, #handler3).argList
		}

		rm = RouteMatch(`/wotever/`, `wot/ever`, #handler3)
		verifyEq(rm.argList.size, 2)
		verifyEq(rm.argList[0], "wot")
		verifyEq(rm.argList[1], "ever")
		
		verifyRouteNotFoundErrMsg(BsMsgs.handlerArgSizeMismatch(#handler3, `wot/ever/dude`)) {
			RouteMatch(`/wotever/`, `wot/ever/dude`, #handler3).argList
		}

		// ---- handler4 ----

		verifyRouteNotFoundErrMsg(BsMsgs.handlerArgSizeMismatch(#handler4, ``)) {
			RouteMatch(`/wotever/`, ``, #handler4).argList
		}

		rm = RouteMatch(`/wotever/`, `wot`, #handler4)
		verifyEq(rm.argList.size, 1)
		verifyEq(rm.argList[0], "wot")
		
		rm = RouteMatch(`/wotever/`, `wot/ever`, #handler4)
		verifyEq(rm.argList.size, 2)
		verifyEq(rm.argList[0], "wot")
		verifyEq(rm.argList[1], "ever")
		
		verifyRouteNotFoundErrMsg(BsMsgs.handlerArgSizeMismatch(#handler4, `wot/ever/dude`)) {
			RouteMatch(`/wotever/`, `wot/ever/dude`, #handler4).argList
		}

		// ---- handler5 ----

		rm = RouteMatch(`/wotever/`, ``, #handler5)
		verifyEq(rm.argList.size, 0)

		rm = RouteMatch(`/wotever/`, `wot`, #handler5)
		verifyEq(rm.argList.size, 1)
		verifyEq(rm.argList[0], "wot")
		
		rm = RouteMatch(`/wotever/`, `wot/ever`, #handler5)
		verifyEq(rm.argList.size, 2)
		verifyEq(rm.argList[0], "wot")
		verifyEq(rm.argList[1], "ever")
		
		verifyRouteNotFoundErrMsg(BsMsgs.handlerArgSizeMismatch(#handler5, `wot/ever/dude`)) {
			RouteMatch(`/wotever/`, `wot/ever/dude`, #handler5).argList
		}
	}
}
