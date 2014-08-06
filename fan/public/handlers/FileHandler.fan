using web::WebReq
using afIoc

** (Service) - Request Handler that maps URLs to files on the file system.
** 
** Example, to map all URLs prefixed with '/pub/' to files under the '<app>/etc/web/' directory, 
** add the following to your 'AppModule':
** 
** pre>
** @Contribute { serviceType=FileHandler# }
** static Void contributeFileHandler(Configuration conf) {
**   conf[`/pub/`] = `etc/web/`.toFile
** }
** <pre
** 
** Use the 'fromServerFile()' to generate client URLs to be used by the browser. Example:
** 
**   // note how the file uses a relative URL
**   fromServerFile(`etc/web/css/mystyle.css`.toFile).clientUrl // --> `/pub/css/mystyle.css` 
** 
** Now when the browser requests the URL '/pub/css/mystyle.css', 'BedSheet' will return the file '<app>/etc/web/css/mystyle.css'.
** 
** It is common to serve files from the root URL:
** 
**   conf[`/`] = `etc/web/`
** 
** That way 'etc/web/' may contain 'etc/web/css/', 'etc/web/images/' and 'etc/web/scripts/'.
** 
** The generated 'clientUrl' contains any extra 'WebMod' path segments required to reach the 'BedSheet WebMod'.
** It also contains path segments as provided by any asset caching strategies, such as [Cold Feet]`http://www.fantomfactory.org/pods/afColdFeet`.
** 
** 
** 
** Fail Fast [#failFast]
** =====================
** An understated advantage of using 'FileHandler' to generate URLs for your assets is that it fails fast.
** 
** Should an asset not exist on the file system (due to a bodged rename, a case sensitivity issue, or other) then 'FileHandler' will throw an Err on the server when the client URI is constructed.
** This allows your web tests to quickly pick up these tricky errors.
** 
** The lesser appealing alternative is for the incorrect URL to be served to the browser which on following, will subsequently receive a '404 - Not Found'.
** While this may not seem a big deal, these errors often go unnoticed and easily find their way into production.
** 
** 
** 
** Precedence with Other Routes [#RoutePrecedence] 
** ===============================================
** The 'FileHandler' directory mappings are automatically added to the `Routes` service on startup.
** That means it is possible to specify a 'Route' URL with more than one handler; a custom handler *and* this 'FileHandler'.
** With a bit of configuration it is possible to specify which takes precedence. 
**   
** The 'FileHandler' route contributions are set with the ID 'afBedSheet.fileHander', so when 'Route' precedence is important, use it in your config: 
** 
** pre>
** @Contribute { serviceType=Routes# }
** static Void contributeRoutes(Configuration config) {
** 
**   // this Route will be served in place of the file 'url1.txt'
**   config.set("beforeExample", Route(`/url1.txt`, ...)).before("afBedSheet.fileHandler")
** 
**   // this Route will be served if there is no file called 'url2.txt'
**   config.set("afterExample", Route(`/url2.txt`, ...)).after("afBedSheet.fileHandler")
** }
** <pre
** 
** @uses Configuration of 'Uri:File'
const mixin FileHandler {

	** Returns the map of URL to directory mappings
	abstract Uri:File directoryMappings()
	
	** The Route handler method. 
	** Returns a 'FileAsset' as mapped from the HTTP request URL or null if not found.
	@NoDoc	// boring route handler method
	abstract FileAsset? serviceRoute(Uri remainingUrl)	
	
	** Given a local URL (a simple URL relative to the WebMod), this returns a corresponding (cached) 'FileAsset'.
	** Throws 'ArgErr' if the URL is not mapped.
	abstract FileAsset fromLocalUrl(Uri localUrl)

	** Given a file on the server, this returns a corresponding (cached) 'FileAsset'. 
	** Throws 'ArgErr' if the file directory is not mapped.
	abstract FileAsset fromServerFile(File serverFile)
}

internal const class FileHandlerImpl : FileHandler {
	
	@Inject	private const HttpRequest? 			httpRequest	// nullable for unit tests
	@Inject	private const FileAssetCache		fileCache
			override const Uri:File 			directoryMappings
		
	new make(Uri:File dirMappings, |This|? in) {
		in?.call(this)
		
		// verify file and uri mappings, normalise the files
		this.directoryMappings = dirMappings.map |file, uri -> File| {
			if (!file.exists)
				throw BedSheetErr(BsErrMsgs.fileNotFound(file))
			if (!file.isDir)
				throw BedSheetErr(BsErrMsgs.fileIsNotDirectory(file))
			if (!uri.isPathOnly)
				throw BedSheetErr(BsErrMsgs.urlMustBePathOnly(uri, `/foo/bar/`))
			if (!uri.isPathAbs)
				throw BedSheetErr(BsErrMsgs.urlMustStartWithSlash(uri, `/foo/bar/`))
			if (!uri.isDir)
				throw BedSheetErr(BsErrMsgs.urlMustEndWithSlash(uri, `/foo/bar/`))
			return file.normalize
		}
	}

	override FileAsset? serviceRoute(Uri remainingUri) {
		try {
			// use pathStr to knockout any unwanted query str
			return fromLocalUrl(httpRequest.url.pathStr.toUri)
		} catch 
			// don't bother making fromLocalUrl() checked, it's too much work for a 404!
			// null means that 'Routes' didn't process the request, so it continues down the pipeline. 
			return null
	}
	
	override FileAsset fromLocalUrl(Uri localUrl) {
		Utils.validateLocalUrl(localUrl, `/css/myStyles.css`)
		
		// TODO: what if 2 dirs map to the same url at the same level? 
		// match the deepest uri
		prefixes:= directoryMappings.keys.findAll { localUrl.toStr.startsWith(it.toStr) }
		prefix 	:= prefixes.size == 1 ? prefixes.first : prefixes.sort |u1, u2 -> Int| { u1.path.size <=> u2.path.size }.last
		if (prefix == null)
			throw BedSheetNotFoundErr(BsErrMsgs.fileHandler_urlNotMapped(localUrl), directoryMappings.keys)

		// We pass 'false' to prevent Errs being thrown if the uri is a dir but doesn't end in '/'.
		// The 'false' appends a '/' automatically - it's nicer web behaviour
		remaining := localUrl.getRange(prefix.path.size..-1).relTo(`/`)
		file	  := directoryMappings[prefix].plus(remaining, false)

		return fromServerFile(file)
	}

	override FileAsset fromServerFile(File file) {
		fileCache.getOrAddOrUpdate(file) |File f->FileAsset| {
			if (file.uri.isDir)
				throw ArgErr(BsErrMsgs.fileIsDirectory(file))
			if (!file.exists)
				throw ArgErr(BsErrMsgs.fileNotFound(file))
			
			fileUri	:= file.normalize.uri.toStr
			prefix  := (Uri?) directoryMappings.eachWhile |af, uri->Uri?| { fileUri.startsWith(af.uri.toStr) ? uri : null }
			if (prefix == null)
				throw BedSheetNotFoundErr(BsErrMsgs.fileHandler_fileNotMapped(file), directoryMappings.vals.map { it.osPath })
			
			matchedFile := directoryMappings[prefix]
			remaining	:= fileUri[matchedFile.uri.toStr.size..-1]
			localUrl	:= prefix + remaining.toUri
			clientUrl	:= fileCache.toClientUrl(localUrl, file)
			
			return FileAsset {
				it.file 		= f
				it.exists		= f.exists
				it.modified		= f.modified?.floor(1sec)
				it.size			= f.size
				it.etag			= it.exists ? "${it.size?.toHex}-${it.modified?.ticks?.toHex}" : null
				it.localUrl		= localUrl
				it.clientUrl	= clientUrl
			}
		}
	}
}

