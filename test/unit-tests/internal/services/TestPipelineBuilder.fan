using afIoc
using concurrent

internal class TestPipelineBuilder : BsTest {
	private Registry? 		 reg
	private PipelineBuilder? bob
	private Obj? 			 term
	private Type?			 t75
	private Type?			 t76

	override Void setup() {
		reg 	= RegistryBuilder().addModule(T_PipeMod#).build.startup
		bob 	= (PipelineBuilder) reg.dependencyByType(PipelineBuilder#)
		term	= T_MyService75Term("T")
		t75		= T_MyService75#
		t76		= T_MyService76#		
	}
	
	Void testPipelineBuilder() {
		num1	:= T_MyService76Num("1")
		num2	:= T_MyService76Num("2")
		num3	:= T_MyService76Num("3")
		
		Actor.locals["test"] = ""
		serv	:= bob.build(t75, t76, [num1, num2, num3], term)
		serv->service()
		
		verifyEq(Actor.locals["test"], "123T")
	}

	Void testPipelineBuilderWithOnlyTerm() {
		Actor.locals["test"] = ""
		serv	:= bob.build(t75, t76, [,], term)
		serv->service()
		
		verifyEq(Actor.locals["test"], "T")
	}
	
	Void testPipelineTypeMustBePublic() {
		verifyBsErrMsg(BsErrMsgs.pipelineTypeMustBePublic("Pipeline", T_MyService77#)) {
			bob.build(T_MyService77#, t76, [,], T_MyService77Impl())
		}
	}
	
	Void testPipelineTypeMustBeMixins() {
		verifyBsErrMsg(BsErrMsgs.pipelineTypeMustBeMixin("Pipeline", T_MyService78#)) {
			bob.build(T_MyService78#, t76, [,], T_MyService78())
		}

		verifyBsErrMsg(BsErrMsgs.pipelineTypeMustBeMixin("Pipeline Filter", T_MyService78#)) {
			bob.build(t75, T_MyService78#, [,], term)
		}
	}

	Void testPipelineMustNotDeclareFields() {
		verifyBsErrMsg(BsErrMsgs.pipelineTypeMustNotDeclareFields(T_MyService79#)) {
			bob.build(T_MyService79#, t76, [,], T_MyService79Impl())
		}
	}

	Void testPipelineTerminatorMustExtendPipelineType() {
		verifyBsErrMsg(BsErrMsgs.pipelineTerminatorMustExtendPipeline(T_MyService77#, term.typeof)) {
			bob.build(T_MyService77#, t76, [,], term)
		}
	}

	Void testPipelineFiltersMustExtendFilterType() {
		verifyBsErrMsg(BsErrMsgs.middlewareMustExtendMiddleware(t76, T_MyService77Impl#)) {
			bob.build(t75, t76, [T_MyService77Impl()], term)
		}
	}

	Void testPipelineFilterMethodMustTakePipelineAsLastArg() {
		verifyBsErrMsg(BsErrMsgs.middlewareMustDeclareMethod(T_MyService77#, "sys::Bool service(, ${t75.qname} handler)")) {
			bob.build(t75, T_MyService77#, [T_MyService77Impl()], term)
		}
	}
	
}

internal const mixin T_MyService77 { }
internal const class T_MyService77Impl : T_MyService77 { }

internal const class T_MyService78 { }

internal mixin T_MyService79 { 
	abstract Str dude
}
internal class T_MyService79Impl : T_MyService79 {
	override Str dude := ""
}

@NoDoc
const mixin T_MyService75 {
	abstract Bool service() 
}     
@NoDoc
const mixin T_MyService76 {
	abstract Bool service(T_MyService75 handler) 
}
@NoDoc
const class T_MyService75Term : T_MyService75 {
	const Str char
	new make(Str char) { this.char = char }
	override Bool service() {
		Actor.locals["test"] = Actor.locals["test"].toStr + char
		return true
	}
}
@NoDoc
const class T_MyService76Num : T_MyService76 {
	const Str char
	new make(Str char) { this.char = char }
	override Bool service(T_MyService75 handler) {
		Actor.locals["test"] = Actor.locals["test"].toStr + char
		return handler.service()
	}
}

internal class T_PipeMod {
	static Void bind(ServiceBinder binder) {
		binder.bindImpl(PipelineBuilder#)
	}
}

