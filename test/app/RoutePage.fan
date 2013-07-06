
internal const class RoutePage {
	
	Obj defaultParams(Str p1, Str p2 := "p2", Str p3 := "p3") {
		TextResponse.fromPlain("$p1 $p2 $p3")
	}

	Obj valEnc(Pinky pinky) {
		TextResponse.fromPlain(pinky.int.toStr)
	}
	
	Obj uri(Uri uri) {
		TextResponse.fromPlain("uri: $uri")
	}
	
}
