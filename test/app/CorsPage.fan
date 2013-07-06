
internal const class CorsPage {
	
	TextResult simple() {
		TextResult.fromPlain("CORS!")
	}

	TextResult preflight() {
		TextResult.fromPlain("Preflight!")
	}
	
}
