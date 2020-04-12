
internal const class RedirectProcessor : ResponseProcessor {
	
	** Convert legacy Redirect to the new HttpRedirect
	override Obj process(Obj response) {
		HttpRedirect.fromLegacy(response)
	}
}
