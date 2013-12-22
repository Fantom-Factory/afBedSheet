using web::WebReq
using afIoc::Inject

** (Service) - A Request Handler that maps URIs to files on the file system.
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
** @uses MappedConfig of 'Uri:File'
const mixin FileHandler {

	** Returns a `File` on the file system as mapped from the given uri, or 'null' if the file does not exist.
	abstract File? service(Uri remainingUri)

}

internal const class FileHandlerImpl : FileHandler {
	
	@Inject
	private const HttpRequest req

	private const Uri:File dirMappings
	
	internal new make(Uri:File dirMappings, |This|? in := null) {
		in?.call(this)	// nullable for unit tests

		// verify file and uri mappings
		dirMappings.each |file, uri| {
			if (!file.exists)
				throw BedSheetErr(BsErrMsgs.fileHandlerFileNotExist(file))
			if (!file.isDir)
				throw BedSheetErr(BsErrMsgs.fileHandlerFileNotDir(file))
			if (!uri.isPathOnly)
				throw BedSheetErr(BsErrMsgs.fileHandlerUriNotPathOnly(uri))
			if (!uri.isPathAbs)
				throw BedSheetErr(BsErrMsgs.fileHandlerUriMustStartWithSlash(uri))
			if (!uri.isDir)
				throw BedSheetErr(BsErrMsgs.fileHandlerUriMustEndWithSlash(uri))
		}

		this.dirMappings = dirMappings.toImmutable
	}

	override File? service(Uri remainingUri) {
		
		// use pathStr to knockout any unwanted query str
		matchedUri := req.modRel.pathStr[0..<-remainingUri.pathStr.size].toUri

		// throw Err if user mapped the Route but forgot to contribute a matching dir to this handler 
		if (!dirMappings.containsKey(matchedUri)) {
			msg := """<p><b>The path '${matchedUri}' is unknown. </b></p>
			          <p><b>Add the following to your AppModule: </b></p>
			          <code>@Contribute { serviceType=FileHandler# }
			          static Void contributeFileMapping(MappedConfig conf) {
			
			            conf[`${matchedUri}`] = `/path/to/files/`.toFile
			
			          }</code>
			          """
			throw HttpStatusErr(501, msg)
		}
		
		// We pass 'false' to prevent Errs being thrown if the uri is a dir but doesn't end in '/'.
		// The 'false' appends a '/' automatically - it's nicer web behaviour
	    file := dirMappings[matchedUri].plus(remainingUri, false)

		// return null if the file doesn't exist so the request can be picked up by another route
		// Note that dirs exist and (currently) return a 403 in the FileResponseProcessor
		return file.exists ? file : null
	}
}
