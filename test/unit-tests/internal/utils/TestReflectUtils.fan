
** Paradox :: Just what is 'Void?'?
class TestReflectUtils : Test {

	Void testFindField() {
		field := ReflectUtils.findField(MyReflectTestUtils2#, "int", Int#)
		verifyEq(field, MyReflectTestUtils2#int)
		field = ReflectUtils.findField(MyReflectTestUtils1#, "int", Int#)
		verifyEq(field, MyReflectTestUtils1#int)

		field = ReflectUtils.findField(MyReflectTestUtils2#, "obj", Obj#)
		verifyEq(field, MyReflectTestUtils1#obj)
		field = ReflectUtils.findField(MyReflectTestUtils1#, "obj", Obj#)
		verifyEq(field, MyReflectTestUtils1#obj)

		field = ReflectUtils.findField(MyReflectTestUtils2#, "int", Num#)
		verifyEq(field, MyReflectTestUtils2#int)
		field = ReflectUtils.findField(MyReflectTestUtils1#, "Obj", Float#)
		verifyNull(field)

		field = ReflectUtils.findField(MyReflectTestUtils1#, "wotever", Float#)
		verifyNull(field)
	}

	Void testFindCtor() {
		ctor := ReflectUtils.findCtor(MyReflectTestUtils2#, "makeCtor2")
		verifyEq(ctor, MyReflectTestUtils2#makeCtor2)
		ctor = ReflectUtils.findCtor(MyReflectTestUtils1#, "makeCtor1")
		verifyEq(ctor, MyReflectTestUtils1#makeCtor1)

		// inherited fields should not found
		ctor = ReflectUtils.findCtor(MyReflectTestUtils2#, "makeCtor1")
		verifyNull(ctor)
	}

	Void testFindMethod() {
		method := ReflectUtils.findMethod(MyReflectTestUtils2#, "method1", [,], false, Void#)
		verifyEq(method, MyReflectTestUtils2#method1)
		method = ReflectUtils.findMethod(MyReflectTestUtils2#, "method1", [,], false, Int#)
		verifyNull(method)
		method = ReflectUtils.findMethod(MyReflectTestUtils2#, "method1", [,], false, Int?#)
		verifyNull(method)

		method = ReflectUtils.findMethod(MyReflectTestUtils2#, "method2", [,], false, Num#)
		verifyEq(method, MyReflectTestUtils2#method2)
		method = ReflectUtils.findMethod(MyReflectTestUtils2#, "method2", [,], false, Num?#)
		verifyEq(method, MyReflectTestUtils2#method2)
		method = ReflectUtils.findMethod(MyReflectTestUtils2#, "method2", [,], false, Obj#)
		verifyEq(method, MyReflectTestUtils2#method2)
		method = ReflectUtils.findMethod(MyReflectTestUtils2#, "method2", [,], false, Obj?#)
		verifyEq(method, MyReflectTestUtils2#method2)
		method = ReflectUtils.findMethod(MyReflectTestUtils2#, "method2", [,], false, Int#)
		verifyNull(method)
		method = ReflectUtils.findMethod(MyReflectTestUtils2#, "method2", [,], false, Int?#)
		verifyNull(method)

		// it seems Nullable has no effect on Type#fits()
		// this makes life easier as we don't have to specify the null '?' all the time
		Obj.echo("Num# == Num?#    -> ${Num# == Num?#}")	// Num# == Num?#    -> false
		Obj.echo("Num#.fits(Num?#) -> ${Num#.fits(Num?#)}")	// Num#.fits(Num?#) -> true
		Obj.echo("Num?#.fits(Num#) -> ${Num?#.fits(Num#)}")	// Num?#.fits(Num#) -> true
		
		method = ReflectUtils.findMethod(MyReflectTestUtils2#, "method3", [,], false, Num#)
//		verifyNull(method)	// this fails!??
		method = ReflectUtils.findMethod(MyReflectTestUtils2#, "method3", [,], false, Num?#)
		verifyEq(method, MyReflectTestUtils2#method3)
		method = ReflectUtils.findMethod(MyReflectTestUtils2#, "method3", [,], false, Obj#)
//		verifyNull(method)	// this fails!??
		method = ReflectUtils.findMethod(MyReflectTestUtils2#, "method3", [,], false, Obj?#)
		verifyEq(method, MyReflectTestUtils2#method3)
		method = ReflectUtils.findMethod(MyReflectTestUtils2#, "method3", [,], false, Int#)
		verifyNull(method)
		method = ReflectUtils.findMethod(MyReflectTestUtils2#, "method3", [,], false, Int?#)
		verifyNull(method)
	}
	
	Void testParams() {
		// simple case
		verify(ReflectUtils.paramTypesFitMethodSignature([,], MyReflectTestUtils2#params1))
		
		// I can pass in more params than required, it's up to the method to say whether it needs 
		// them or not - but if it DOES declare the params then they have to fit
		// Nullable types don't matter as null is mainly a runtime check, to nip it in the bud at source
		verify(ReflectUtils.paramTypesFitMethodSignature([Obj#], MyReflectTestUtils2#params1))

		verifyFalse	(ReflectUtils.paramTypesFitMethodSignature([,],    MyReflectTestUtils2#params2))
		verify		(ReflectUtils.paramTypesFitMethodSignature([Num#], MyReflectTestUtils2#params2))
		verifyFalse	(ReflectUtils.paramTypesFitMethodSignature([Obj#], MyReflectTestUtils2#params2))
		verify		(ReflectUtils.paramTypesFitMethodSignature([Int#], MyReflectTestUtils2#params2))
		verify		(ReflectUtils.paramTypesFitMethodSignature([Int#, Int#], MyReflectTestUtils2#params2))

		verifyFalse	(ReflectUtils.paramTypesFitMethodSignature([,],    MyReflectTestUtils2#params3))
		verify		(ReflectUtils.paramTypesFitMethodSignature([Num#], MyReflectTestUtils2#params3))
		verifyFalse	(ReflectUtils.paramTypesFitMethodSignature([Obj#], MyReflectTestUtils2#params3))
		verify		(ReflectUtils.paramTypesFitMethodSignature([Int#], MyReflectTestUtils2#params3))
		verify		(ReflectUtils.paramTypesFitMethodSignature([Int#, Int#], MyReflectTestUtils2#params3))

		verify		(ReflectUtils.paramTypesFitMethodSignature([,],    MyReflectTestUtils2#params4))
		verify		(ReflectUtils.paramTypesFitMethodSignature([Num#], MyReflectTestUtils2#params4))
		verifyFalse	(ReflectUtils.paramTypesFitMethodSignature([Obj#], MyReflectTestUtils2#params4))
		verify		(ReflectUtils.paramTypesFitMethodSignature([Int#], MyReflectTestUtils2#params4))
		verify		(ReflectUtils.paramTypesFitMethodSignature([Int#, Int#], MyReflectTestUtils2#params4))

		verify		(ReflectUtils.paramTypesFitMethodSignature([,],    MyReflectTestUtils2#params5))
		verify		(ReflectUtils.paramTypesFitMethodSignature([Num#], MyReflectTestUtils2#params5))
		verifyFalse	(ReflectUtils.paramTypesFitMethodSignature([Obj#], MyReflectTestUtils2#params5))
		verify		(ReflectUtils.paramTypesFitMethodSignature([Int#], MyReflectTestUtils2#params5))
		verify		(ReflectUtils.paramTypesFitMethodSignature([Int#, Int#], MyReflectTestUtils2#params5))

		verifyFalse	(ReflectUtils.paramTypesFitMethodSignature([,],			 MyReflectTestUtils2#params6))
		verify		(ReflectUtils.paramTypesFitMethodSignature([Num#], 		 MyReflectTestUtils2#params6))
		verify		(ReflectUtils.paramTypesFitMethodSignature([Num#, Num#], MyReflectTestUtils2#params6))
		verifyFalse	(ReflectUtils.paramTypesFitMethodSignature([Num#, Obj#], MyReflectTestUtils2#params6))
		verify		(ReflectUtils.paramTypesFitMethodSignature([Num#, Int#], MyReflectTestUtils2#params6))
		verify		(ReflectUtils.paramTypesFitMethodSignature([Num#, Int#, Int#], MyReflectTestUtils2#params6))

		verifyFalse	(ReflectUtils.paramTypesFitMethodSignature([,],			 MyReflectTestUtils2#params7))
		verify		(ReflectUtils.paramTypesFitMethodSignature([Num#], 		 MyReflectTestUtils2#params7))
		verify		(ReflectUtils.paramTypesFitMethodSignature([Num#, Num#], MyReflectTestUtils2#params7))
		verifyFalse	(ReflectUtils.paramTypesFitMethodSignature([Num#, Obj#], MyReflectTestUtils2#params7))
		verify		(ReflectUtils.paramTypesFitMethodSignature([Num#, Int#], MyReflectTestUtils2#params7))
		verify		(ReflectUtils.paramTypesFitMethodSignature([Num#, Int#, Int#], MyReflectTestUtils2#params7))

		verify		(ReflectUtils.paramTypesFitMethodSignature([,],			 MyReflectTestUtils2#params8))
		
		// test I can call a method with more params than it declares
		MyReflectTestUtils2#params1.callOn(MyReflectTestUtils2(), [48, 45])
	}
	
	Void testKnarlyFuncsInParams() {
		Obj.echo("Func#.fits(|Num?|) -> ${Func#.fits(|Num?|#)}")	// Func#.fits(|Num?|#) -> false
		Obj.echo("|Num?|#.fits(Func#) -> ${|Num?|#.fits(Func#)}")	// |Num?|#.fits(Func#) -> true
		
		// these tests aren't my understanding, they just demonstrate what does and doesn't work!
		verifyFalse	(ReflectUtils.paramTypesFitMethodSignature([Func#],			MyReflectTestUtils2#funcy1))
		verify		(ReflectUtils.paramTypesFitMethodSignature([|->|#],			MyReflectTestUtils2#funcy1))
		verify		(ReflectUtils.paramTypesFitMethodSignature([|Num|#], 		MyReflectTestUtils2#funcy1))
		verify		(ReflectUtils.paramTypesFitMethodSignature([|Obj|#], 		MyReflectTestUtils2#funcy1))
		verifyFalse	(ReflectUtils.paramTypesFitMethodSignature([|Int|#], 		MyReflectTestUtils2#funcy1))
		verifyFalse	(ReflectUtils.paramTypesFitMethodSignature([|Int, Int|#],	MyReflectTestUtils2#funcy1))		

		verifyFalse	(ReflectUtils.paramTypesFitMethodSignature([|Num|#], 		MyReflectTestUtils2#funcy2))
		verify		(ReflectUtils.paramTypesFitMethodSignature([|Num->Num|#], 	MyReflectTestUtils2#funcy2))
		verifyFalse	(ReflectUtils.paramTypesFitMethodSignature([|Num->Obj|#], 	MyReflectTestUtils2#funcy2))
		verify		(ReflectUtils.paramTypesFitMethodSignature([|Num->Int|#], 	MyReflectTestUtils2#funcy2))
	}
	
}


internal class MyReflectTestUtils1 {
	virtual Int int
	Obj obj	:= 4
	
	new makeCtor1() { }
}

internal class MyReflectTestUtils2 : MyReflectTestUtils1 { 
	override Int int := 6
	
	new makeCtor2() { }
	
	Void method1() { }
	Num  method2() { return 69 }
	Num? method3() { return 69 }
	
	Void params1() { }
	Void params2(Num num) { }
	Void params3(Num? num) { }
	Void params4(Num num := 0) { }
	Void params5(Num? num := 0) { }
	Void params6(Num num, Num num2 := 0) { }
	Void params7(Num num, Num? num2 := 0) { }
	Void params8(Num num := 0, Num? num2 := 0) { }
	
	Void funcy1(|Num?| f) { }
	Void funcy2(|Num?->Num| f) { }
}
