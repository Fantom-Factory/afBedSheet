using afIoc::Inject
using web::FileWeblet

internal const class FileResultProcessor : ResultProcessor {
	
	@Inject
	private const Request request
	
	new make(|This|in) { in(this) }
	
	override Void process(Obj result) {
		file := (File) result
		
		if (!file.exists)
			throw HttpStatusErr(404, "File not found: $request.modRel")
		
		// I dunno if this should be a 403 or 404. 
		// 403 gives any would be attacker info about your server.
		if (file.isDir)	// not allowed, until I implement it! 
			throw HttpStatusErr(403, "Directory listing not allowed: $request.modRel")
		
		FileWeblet(file).onGet
	}
}
