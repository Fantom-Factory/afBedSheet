using afIoc3
using afPlastic
using concurrent

internal class TestMiddlewarePipeline : BsTest {
	
	Void testPipelineBuilder() {
		num1		:= T_MyService76Num("1")
		num2		:= T_MyService76Num("2")
		num3		:= T_MyService76Num("3")
		reqState	:= Unsafe(RequestState())
		
		Actor.locals["test"] = ""
		serv	:= MiddlewarePipelineImpl([num1, num2, num3, T_MyService75Term("T")]) {
			it.reqState = |->RequestState| { reqState.val }
		}
		serv.service
		
		verifyEq(Actor.locals["test"], "123T")
	}

	Void testPipelineBuilderWithOnlyTerm() {
		reqState := Unsafe(RequestState())
		Actor.locals["test"] = ""
		serv	:= MiddlewarePipelineImpl([T_MyService75Term("T")]){
			it.reqState = |->RequestState| { reqState.val }
		}
		serv.service
		
		verifyEq(Actor.locals["test"], "T")
	}
	
}

@NoDoc
const class T_MyService75Term : Middleware {
	const Str char
	new make(Str char) { this.char = char }
	override Void service(MiddlewarePipeline handler) {
		Actor.locals["test"] = Actor.locals["test"].toStr + char
	}
}

@NoDoc
const class T_MyService76Num : Middleware {
	const Str char
	new make(Str char) { this.char = char }
	override Void service(MiddlewarePipeline handler) {
		Actor.locals["test"] = Actor.locals["test"].toStr + char
		return handler.service
	}
}
