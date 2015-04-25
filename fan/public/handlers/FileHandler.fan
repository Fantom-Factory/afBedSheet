using web::WebReq
using afIoc

** (Service) - 
** A 'ClientAssetProducer' that maps URLs to files on the file system.
** Use to serve up file assets.
** 
** Suppose your project has this directory structure:
** 
** pre>
** myProj/
**  |-- fan/
**  |-- test/
**  `-- etc
**       `-- static-web/
**            |-- css/
**            |    `-- app.css
**            |-- images/
**            |    `-- logo.png
**            `-- scripts/
** <pre
** 
** To serve up files from the 'css/' directory add the following to 'AppModule':
** 
** pre>
** @Contribute { serviceType=FileHandler# }
** static Void contributeFileHandler(Configuration conf) {
**   conf[`/stylesheets/`] = `etc/static-web/css/`.toFile
** }
** <pre
** 
** Browsers may then access 'app.css' with the URL '/stylesheets/app.css'.
** 
** Rather than hardcoding '/stylesheets/app.css' in HTML, it is better to generate a client URL from 'FileHandler'.
** 
**   urlStr := fileHandler.fromLocalUrl(`/stylesheets/app.css`).clientUrl.encode
** 
** Most of the time 'urlStr' will be the same as the hardcoded URL but it has the added benefit of:
**  - Failing fast if the file does not exist
**  - generating correct URLs in non-root WebMods
**  - utilising an asset caching strategy
**
** The generated 'clientUrl' contains any extra 'WebMod' path segments required to reach the 'BedSheet WebMod'.
** It is also transformed by asset caching strategies such as [Cold Feet]`http://www.fantomfactory.org/pods/afColdFeet`.
**  
** 
** 
** Serve All Root Directories [#serveAllDirs]
** ==========================================
** Using the above example, extra config would need to be added to serve the 'images/' and the 'scripts/' directories. 
** This is not ideal. So to serve all the files and directories under 'etc/static-web/' add config for the root URL:  
** 
**   conf[`/`] = `etc/static-web/`.toFile
** 
** This way everything under 'etc/static-web/' is served as is. Example, 'logo.png' is accessed with the URL '/images/logo.png'.
** 
** 
** 
** Fail Fast [#failFast]
** =====================
** An understated advantage of using 'FileHandler' to generate client URLs is that it fails fast.
** 
** Should an asset not exist on the file system (due to a bodged rename, a case sensitivity issue, or other) then 'FileHandler' will throw an Err on the server when the client URL is constructed.
** This allows your web tests to quickly pick up these tricky errors.
** 
** The lesser appealing alternative is for the incorrect URL to be served to the browser which on following, will subsequently receive a '404 - Not Found'.
** While this may not seem a big deal, these errors often go unnoticed and easily find their way into production.
** 
** 
** 
** Precedence with Other Routes [#RoutePrecedence] 
** ===============================================
** 'FileHandler' is a 'ClientAssetProducer' so file assets are served by the Asset Middleware. 
** By default the Asset Middleware is processed before the Routes Middleware so should an asset and 
** Route serve the same URL, the asset takes precedence. (Meaning the asset is served and Route is not processed.)
** 
** @uses Configuration of 'Uri:File'
const mixin FileHandler : ClientAssetProducer {

	** Returns the map of URL to directory mappings
	abstract Uri:File directoryMappings()
	
	** Given a local URL (a simple URL relative to the WebMod), this returns a corresponding (cached) 'FileAsset'.
	**  
	**   url := fileHandler.fromLocalUrl(`/stylesheets/app.css`).clientUrl.encode
	** 
	** Throws 'ArgErr' if the checked and file does not exist, 'null' otherwise.
	abstract override ClientAsset? fromLocalUrl(Uri localUrl, Bool checked := true)

	** Given a file on the server, this returns a corresponding (cached) 'ClientAsset'.
	**  
	** Throws 'ArgErr' if the checked and file does not exist, 'null' otherwise.
	abstract ClientAsset? fromServerFile(File serverFile, Bool checked := true)
	
	** Finds the directory mapping that best fits the given local URL, or 'null' if not found.
	@NoDoc	// Experimental advanced use - see Duvet
	abstract Uri? findMappingFromLocalUrl(Uri localUrl)
}

internal const class FileHandlerImpl : FileHandler {
	
	@Inject	private const HttpRequest? 		httpRequest	// nullable for unit tests
	@Inject	private const ClientAssetCache	assetCache
	@Inject	private const Registry			registry
			override const Uri:File 		directoryMappings
		
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
	
	override Uri? findMappingFromLocalUrl(Uri localUri) {
		Utils.validateLocalUrl(localUri, `/css/myStyles.css`)
		// TODO: what if 2 dirs map to the same url at the same level?

		// use pathStr to knockout any unwanted query str
		localUrl := localUri.pathStr.toUri

		// match the deepest uri
		prefixes:= directoryMappings.keys.findAll { localUrl.toStr.startsWith(it.toStr) }
		prefix 	:= prefixes.size == 1 ? prefixes.first : prefixes.sort |u1, u2 -> Int| { u1.path.size <=> u2.path.size }.last
		return prefix
	}

	override ClientAsset? fromLocalUrl(Uri localUrl, Bool checked := true) {
		prefix	:= findMappingFromLocalUrl(localUrl)
		
		if (prefix == null)
			if (checked) throw BedSheetNotFoundErr(BsErrMsgs.fileHandler_urlNotMapped(localUrl), directoryMappings.keys) 
			else return null

		// We pass 'false' to prevent Errs being thrown if the uri is a dir but doesn't end in '/'.
		// The 'false' appends a '/' automatically - it's nicer web behaviour
		remaining := localUrl.getRange(prefix.path.size..-1).relTo(`/`)
		file	  := directoryMappings[prefix].plus(remaining, false)

		return fromServerFile(file, checked)
	}

	override ClientAsset? fromServerFile(File file, Bool checked := true) {
		fileUri	:= file.normalize.uri.toStr
		prefix  := (Uri?) directoryMappings.eachWhile |af, uri->Uri?| { fileUri.startsWith(af.uri.toStr) ? uri : null }
		if (prefix == null)
			if (checked) throw BedSheetNotFoundErr(BsErrMsgs.fileHandler_fileNotMapped(file), directoryMappings.vals.map { it.osPath })
			else return null
		
		matchedFile := directoryMappings[prefix]
		remaining	:= fileUri[matchedFile.uri.toStr.size..-1]
		localUrl	:= prefix + remaining.toUri

		return assetCache.getOrAddOrUpdate(localUrl) |Uri key->ClientAsset?| {
			// don't throw HttpStatusErrs 'cos this is an API call (for template generation), not a response. 
			if (file.isDir)	// not allowed, until I implement it! 
				if (checked) throw ArgErr(BsErrMsgs.directoryListingNotAllowed(localUrl))	// should be clientUrl - pfft.
				else return null
			if (!file.exists)
				if (checked) throw ArgErr(BsErrMsgs.fileNotFound(file))
				else return null

			return registry.autobuild(FileAsset#, [localUrl, file])
		}
	}
}
