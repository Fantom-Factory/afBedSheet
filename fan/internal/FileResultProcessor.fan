using afIoc::Inject
using web::FileWeblet

internal const class FileResultProcessor : HandlerResultProcessor {
	
	@Inject
	private const Request request
	
	new make(|This|in) { in(this) }
	
	override Void process(Obj result) {
		file := (File) result
		
		if (!file.exists)
			throw HttpStatusErr(404, "File not found: $request.modRel")
		
		if (file.isDir)	// not allowed, until I implement it! Make them pluggable.
			throw HttpStatusErr(403, "Directory listing not allowed: $request.modRel")
		
		FileWeblet(file).onGet
	}
}
