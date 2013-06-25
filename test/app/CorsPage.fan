
internal const class CorsPage {
	
	TextResult simple(Uri uri) {
		TextResult.fromPlain("CORS!")
	}

	TextResult preflight(Uri uri) {
		TextResult.fromPlain("Preflight!")
	}
	
}
