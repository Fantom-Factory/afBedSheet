using concurrent::Actor

internal class TestResponseProcessors : BsTest {

	Void testProcessOne() {
		Actor.locals["respro02"] = null
		map := [Str#:T_ResPro02()]
		rp := ResponseProcessorsImpl(map)
		
		rp.processResponse("Dude")
		verify(Actor.locals["respro02"])
	}

	Void testFallThrough() {
		Actor.locals["respro01"] = null
		Actor.locals["respro02"] = null
		map := [Int#:T_ResPro01(), Str#:T_ResPro02()]
		rp := ResponseProcessorsImpl(map)
		
		rp.processResponse(3)
		verify(Actor.locals["respro01"])
		verify(Actor.locals["respro02"])
	}

	Void testProcessErr() {
		map := [Int#:T_ResPro01()]
		rp := ResponseProcessorsImpl(map)
		
		verifyErr(UnknownResponseObjectErr#) {
			rp.processResponse("Die!")			
		}
	}
	
}

internal const class T_ResPro01: ResponseProcessor {
	override Obj process(Obj response) {
		Actor.locals["respro01"] = true
		return response.toStr
	}
}

internal const class T_ResPro02 : ResponseProcessor {
	override Obj process(Obj response) {
		Actor.locals["respro02"] = true
		return true
	}	
}