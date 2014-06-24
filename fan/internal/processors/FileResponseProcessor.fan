using afIoc::Inject
using web::WebUtil

internal const class FileResponseProcessor : ResponseProcessor {
	
	@Inject	private const FileHandler 	fileHandler
	
	new make(|This|in) { in(this) }

	// simply convert the File into a FileAsset...
	override Obj process(Obj fileObj) {
		file := ((File) fileObj).normalize
		return FileAsset {
			it.file 		= file
			it.exists		= file.exists
			it.modified		= file.modified?.floor(1sec)
			it.size			= file.size
			it.etag			= it.exists ? "${it.size?.toHex}-${it.modified?.ticks?.toHex}" : null
			it.localUrl		= null
			it.clientUrl	= null
		}		
	}
}
