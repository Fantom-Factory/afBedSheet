using afIoc::Inject
using web::WebUtil

internal const class FileProcessor : ResponseProcessor {
	
	@Inject	private const FileHandler 	fileHandler
	
	new make(|This|in) { in(this) }

	// simply convert the File into a FileAsset...
	override Obj process(Obj fileObj) {
		file := ((File) fileObj).normalize
		return FileAsset(file)
	}
}
