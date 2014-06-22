using web::WebReq
using afIoc::Inject

** (Service) - Request Handler that maps URIs to files on the file system.
** 
** Example, to map all uris prefixed with '/pub/' to files under the '<app>/etc/web/' directory, 
** add the following to your 'AppModule':
** 
** pre>
** @Contribute { serviceType=FileHandler# }
** static Void contributeFileHandler(MappedConfig conf) {
**   conf[`/pub/`] = `etc/web/`.toFile
** }
** <pre
** 
** Use the 'fromServerFile()' method to generate URIs to be used by the browser. Example:
** 
**   // note how the file uses a relative URI
**   fromServerFile(`etc/web/css/mystyle.css`.toFile) // --> `/pub/css/mystyle.css` 
** 
** Now when the browser requests '/pub/css/mystyle.css', BedSheet will return the file '<app>/etc/web/css/mystyle.css'.
** 
** It is common to serve files from the root uri:
** 
**   conf[`/`] = `etc/web/`
** 
** `Route` mappings are automatically added to the `Routes` service, and are sandwiched in between 'FileHanderStart' and 
** 'FileHandlerEnd' place holders. Use these when 'Route' precedence is important:
** 
** pre>
** @Contribute { serviceId="Routes" }
** static Void contributeRoutes(OrderedConfig config) {
** 
**   // this Route will be served in place of the file 'uri1.txt'
**   config.addOrdered("uri1", Route(`/uri1.txt`, ...), ["before: FileHandlerStart"])
** 
**   // this Route will be served if there is no file called 'uri.txt'
**   config.addOrdered("uri2", Route(`/uri2.txt`, ...), ["after: FileHandlerEnd"])
** }
** <pre
** 
** @uses MappedConfig of 'Uri:File'
const mixin FileHandler {

	** Returns the map of uri to directory mappings
	abstract Uri:File directoryMappings()
	
	** Returns a `File` on the file system as mapped from the given uri, or 'null' if the file does not exist.
	abstract File? service(Uri remainingUri)
	
	** Returns the server file that the client-side asset URI maps to. 
	** 
	** If 'checked' is 'true' throw ArgErr if the file does not exist, else return 'null'.
	abstract File? fromClientUrl(Uri clientUrl, Bool checked := true)

	** Returns the client URI that corresponds to the given asset file.
	** 
	** Throws a 'NotFoundErr' if the file does not reside in a mapped directory. 
	abstract Uri fromServerFile(File serverFile)

	@NoDoc @Deprecated { msg="use fromClientUrl instead" }
	File? fromClientUri(Uri assetUri, Bool checked := true) {
		fromClientUrl(assetUri, checked)
	}
}

internal const class FileHandlerImpl : FileHandler {
	
	@Inject	private const HttpRequest? 		req			// nullable for unit tests
	@Inject	private const FileMetaCache?	fileCache	// nullable for unit tests

	override const Uri:File directoryMappings
	
	new make(Uri:File dirMappings, |This|? in := null) {
		in?.call(this)	// nullable for unit tests

		// verify file and uri mappings, normalise the files
		this.directoryMappings = dirMappings.map |file, uri -> File| {
			if (!file.exists)
				throw BedSheetErr(BsErrMsgs.fileHandlerFileNotExist(file))
			if (!file.isDir)
				throw BedSheetErr(BsErrMsgs.fileHandlerFileNotDir(file))
			if (!uri.isPathOnly)
				throw BedSheetErr(BsErrMsgs.fileHandlerUrlNotPathOnly(uri, `/foo/bar/`))
			if (!uri.isPathAbs)
				throw BedSheetErr(BsErrMsgs.fileHandlerUrlMustStartWithSlash(uri, `/foo/bar/`))
			if (!uri.isDir)
				throw BedSheetErr(BsErrMsgs.fileHandlerUrlMustEndWithSlash(uri))
			return file.normalize
		}
	}

	override File? service(Uri remainingUri) {
		// use pathStr to knockout any unwanted query str
		matchedUri := req.modRel.pathStr[0..<-remainingUri.pathStr.size].toUri
		return fromClientUrl(matchedUri.plusSlash + remainingUri, false)		
	}
	
	override File? fromClientUrl(Uri clientUrl, Bool checked := true) {
		if (clientUrl.host != null || !clientUrl.isRel)
			throw ArgErr(BsErrMsgs.fileHandlerUrlNotPathOnly(clientUrl, `/css/myStyles.css`))
		if (!clientUrl.isPathAbs)
			throw ArgErr(BsErrMsgs.fileHandlerUrlMustStartWithSlash(clientUrl, `/css/myStyles.css`))
		
		// match the deepest uri
		prefix 	:= (Uri?) directoryMappings.keys.findAll { clientUrl.toStr.startsWith(it.toStr) }.sort |u1, u2 -> Int| { u1.toStr.size <=> u2.toStr.size }.last
		if (prefix == null)
			return null ?: (checked ? throw BedSheetNotFoundErr(BsErrMsgs.fileHandlerUrlNotMapped(clientUrl), directoryMappings.keys) : null)

		// We pass 'false' to prevent Errs being thrown if the uri is a dir but doesn't end in '/'.
		// The 'false' appends a '/' automatically - it's nicer web behaviour
		remaining := clientUrl.getRange(prefix.path.size..-1).relTo(`/`)
		file	  := directoryMappings[prefix].plus(remaining, false)

		fileMeta  := fileCache[file]
		
		if (checked && !fileMeta.exists)
			throw ArgErr(BsErrMsgs.fileHandlerUrlDoesNotExist(clientUrl, file))

		return fileMeta.exists ? file : null
	}

	override Uri fromServerFile(File assetFile) {
		fileMeta  := fileCache[assetFile]
		if (fileMeta.isDir)
			throw ArgErr(BsErrMsgs.fileHandlerAssetFileIsDir(assetFile))
		if (!fileMeta.exists)
			throw ArgErr(BsErrMsgs.fileHandlerAssetFileDoesNotExist(assetFile))
		
		assetUriStr := assetFile.normalize.uri.toStr
		prefix  	:= directoryMappings.findAll |file, uri->Bool| { assetUriStr.startsWith(file.uri.toStr) }.keys.sort |u1, u2 -> Int| { u1.toStr.size <=> u2.toStr.size }.last
		if (prefix == null)
			throw BedSheetNotFoundErr(BsErrMsgs.fileHandlerAssetFileNotMapped(assetFile), directoryMappings.vals.map { it.osPath })
		
		matchedFile := directoryMappings[prefix]
		remaining	:= assetUriStr[matchedFile.uri.toStr.size..-1]
		assetUri	:= prefix + remaining.toUri
		
		return assetUri
	}
}

