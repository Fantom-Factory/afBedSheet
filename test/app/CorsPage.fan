
internal const class CorsPage {
	
	TextResponse simple() {
		TextResponse.fromPlain("CORS!")
	}

	TextResponse preflight() {
		TextResponse.fromPlain("Preflight!")
	}
	
}
