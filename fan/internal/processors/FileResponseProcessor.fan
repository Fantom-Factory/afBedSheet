using afIoc::Inject
using web::FileWeblet

internal const class FileResponseProcessor : ResponseProcessor {
	
	@Inject
	private const HttpRequest request
	
	new make(|This|in) { in(this) }
	
	override Obj process(Obj response) {
		file := (File) response
		
		if (!file.exists)
			throw HttpStatusErr(404, "File not found: $request.modRel")
		
		// I dunno if this should be a 403 or 404. 
		// 403 gives any would be attacker info about your server.
		if (file.isDir)	// not allowed, until I implement it! 
			throw HttpStatusErr(403, "Directory listing not allowed: $request.modRel")
		
		FileWeblet(file).onGet
		return true
	}
}
