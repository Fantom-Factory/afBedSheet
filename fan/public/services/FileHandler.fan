using web::WebReq
using afIoc::Inject

** Maps files to URIs
** 
** @uses MappedConfig of Uris to Files
const class FileHandler {
	
	@Inject
	private const Request req

	private const Uri:File dirMappings
	
	new make(Uri:File dirMappings, |This|? in := null) {
		in?.call(this)
		
		// verify file and uri mappings
		dirMappings.each |file, uri| {
			if (!file.exists)
				throw BedSheetErr(BsMsgs.fileHandlerFileNotExist(file))
			if (!file.isDir)
				throw BedSheetErr(BsMsgs.fileHandlerFileNotDir(file))
			if (!uri.isPathOnly)
				throw BedSheetErr(BsMsgs.fileHandlerUriNotPathOnly(uri))
			if (!uri.isPathAbs)
				throw BedSheetErr(BsMsgs.fileHandlerUriMustStartWithSlash(uri))
			if (!uri.isDir)
				throw BedSheetErr(BsMsgs.fileHandlerUriMustEndWithSlash(uri))
		}
		
		this.dirMappings = dirMappings.toImmutable
	}

	** Returns a File on the file system, mapped from the given config
	File service(Uri routeRel) {
	    dirMappings[req.routeBase] + routeRel
	}
}
