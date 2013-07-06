using web::WebReq
using afIoc::Inject

** A Request Handler that maps uris to files on the file system.
** 
** Example, to map all uris prefixed with '/pub/' to files under the '<app>/etc/web/' directory, 
** in your AppModule:
** 
** pre>
** @Contribute { serviceType=FileHandler# }
** static Void contributeFileHandler(MappedConfig conf) {
**   conf[`/pub/`] = `etc/web/`.toFile
** }
** <pre
** 
** Don't forget to `Route` '/pub/***' URIs to 'FileHandler':
**
** pre>
** @Contribute { serviceType=Routes# }
** static Void contributeRoutes(OrderedConfig conf) {
**   ...
**   conf.add(Route(`/pub/***`, FileHandler#service))
**   ...
** }
** <pre
** 
** Now all requests to '/pub/css/mystyle.css' will map to 'etc/web/css/mystyle.css'
** 
** @uses MappedConfig of Uri:File
const class FileHandler {
	
	@Inject
	private const Request req

	private const Uri:File dirMappings
	
	internal new make(Uri:File dirMappings, |This|? in := null) {
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

	** Returns a `File` on the file system, as mapped from the given route relative uri.
	File service(Uri remainingUri := ``) {
		
		// use pathStr to knockout any unwanted query str
		matchedUri := req.modRel.pathStr[0..<-remainingUri.pathStr.size].toUri

		// We pass 'false' to prevent Errs being thrown if the uri is a dir but doesn't end in '/'.
		// The 'false' appends a '/' automatically - it's nicer web behaviour
		// FUTURE: configure this behaviour once we've thought up a nice name for the config!
	    return dirMappings[matchedUri].plus(remainingUri, false)
		
		// currently it's the FileResponseProcessor that throws a 404 if the file doesn't exist
	}
}