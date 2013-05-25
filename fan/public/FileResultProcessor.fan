using web::FileWeblet

const class FileResultProcessor : ResultProcessor {
	
	override Void process(Obj result) {
		file := (File) result
		
		if (!file.exists)
			throw Err("404")	// FIXME
		
		FileWeblet(file).onService
	}
}
