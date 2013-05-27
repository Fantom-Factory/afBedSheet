
internal const class RoutePage {
	
	Obj defaultParams(Str p1, Str p2 := "p2", Str p3 := "p3") {
		TextResult.fromPlain("$p1 $p2 $p3")
	}
	
}
