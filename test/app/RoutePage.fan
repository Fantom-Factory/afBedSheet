
internal const class RoutePage {
	
	Obj defaultParams(Str p1, Str p2 := "p2", Str p3 := "p3") {
		TextResult.fromPlain("$p1 $p2 $p3")
	}

	Obj valEnc(Pinky pinky) {
		TextResult.fromPlain(pinky.str)
	}
	
	Obj uri(Uri uri) {
		TextResult.fromPlain("uri: $uri")
	}
	
	Obj list(Str[] list) {
		TextResult.fromPlain("uri: $list")
	}
	
}
