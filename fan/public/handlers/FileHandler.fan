using web::WebReq
using afIoc
using afIocEnv
using afConcurrent
using concurrent

** (Service) - Request Handler that maps URLs to files on the file system.
** 
** Example, to map all URLs prefixed with '/pub/' to files under the '<app>/etc/web/' directory, 
** add the following to your 'AppModule':
** 
** pre>
** @Contribute { serviceType=FileHandler# }
** static Void contributeFileHandler(MappedConfig conf) {
**   conf[`/pub/`] = `etc/web/`.toFile
** }
** <pre
** 
** Use the 'fromServerFile()' method to generate URLs to be used by the browser. Example:
** 
**   // note how the file uses a relative URL
**   fromServerFile(`etc/web/css/mystyle.css`.toFile).clientUrl // --> `/pub/css/mystyle.css` 
** 
** Now when the browser requests the URL '/pub/css/mystyle.css', 'BedSheet' will return the file '<app>/etc/web/css/mystyle.css'.
** 
** It is common to serve files from the root uri:
** 
**   conf[`/`] = `etc/web/`
** 
** The 'clientUrl' contains any extra 'WebMod' path segments required to reach the 'BedSheet WebMod'.
** It also contains path segments as provided by any asset caching strategies, such as [Cold Feet]`http://www.fantomfactory.org/pods/afColdFeet`.
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

	** Returns the map of URL to directory mappings
	abstract Uri:File directoryMappings()
	
	** Given a local URL (a simple URL relative to the WebMod), this returns a corresponding (cached) 'FileAsset'.
	** Throws 'ArgErr' if the URL is not mapped.
	abstract FileAsset fromLocalUrl(Uri localUrl)

	** Given a file on the server, this returns a corresponding (cached) 'FileAsset'. 
	** Throws 'ArgErr' if the file directory is not mapped.
	abstract FileAsset fromServerFile(File serverFile)
	
	@NoDoc	// boring route handler method
	abstract FileAsset? service(Uri remainingUrl)
	
	** Hook for asset caching strategies to advise and transform URLs.
	@NoDoc
	abstract Uri toClientUrl(Uri localUrl)
	
	** Removes the given 'FileAsset' from the internal cache.
	@NoDoc	// hide the leaky abstraction
	abstract Void removeFileAsset(FileAsset fileAsset)

	** Clears the internal 'FileAsset' cache.
	@NoDoc	// hide the leaky abstraction
	abstract Void clear()
}



internal const class FileHandlerImpl : FileHandler {
	
	@Inject	private const HttpRequest? 			httpRequest	// nullable for unit tests
	@Inject	private const Registry	 			registry	// it's me!!!
			private	const SynchronizedFileMap	fileCache
			override const Uri:File 			directoryMappings
	
					** The duration between individual file checks.
					const Duration 				cacheTimeout
	
	new make(Uri:File dirMappings, IocEnv env, ActorPools actorPools, |This|? in) {
		this.cacheTimeout = env.isProd ? 2min : 2sec
		
		in?.call(this)
		
		this.fileCache = SynchronizedFileMap(actorPools["afBedSheet.system"], cacheTimeout) { it.valType = FileAsset# }

		// verify file and uri mappings, normalise the files
		this.directoryMappings = dirMappings.map |file, uri -> File| {
			if (!file.exists)
				throw BedSheetErr(BsErrMsgs.fileHandler_dirNotFound(file))
			if (!file.isDir)
				throw BedSheetErr(BsErrMsgs.fileHandler_notDir(file))
			if (!uri.isPathOnly)
				throw BedSheetErr(BsErrMsgs.fileHandler_urlNotPathOnly(uri, `/foo/bar/`))
			if (!uri.isPathAbs)
				throw BedSheetErr(BsErrMsgs.fileHandler_urlMustStartWithSlash(uri, `/foo/bar/`))
			if (!uri.isDir)
				throw BedSheetErr(BsErrMsgs.fileHandler_urlMustEndWithSlash(uri))
			return file.normalize
		}
	}

	override FileAsset? service(Uri remainingUri) {
		try {
			// use pathStr to knockout any unwanted query str
			matchedUri := httpRequest.modRel.pathStr[0..<-remainingUri.pathStr.size].toUri
			return fromLocalUrl(matchedUri.plusSlash + remainingUri)
		} catch 
			// don't bother making fromLocalUrl() checked, it's too much work for a 404!
			// null means that Routes didn't process the request, so it continues down the pipeline. 
			return null
	}
	
	override FileAsset fromLocalUrl(Uri localUrl) {
		if (localUrl.host != null || !localUrl.isRel)	// can't use Uri.isPathOnly because we allow QueryStrs and Fragments...?
			throw ArgErr(BsErrMsgs.fileHandler_urlNotPathOnly(localUrl, `/css/myStyles.css`))
		if (!localUrl.isPathAbs)
			throw ArgErr(BsErrMsgs.fileHandler_urlMustStartWithSlash(localUrl, `/css/myStyles.css`))
		
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
				throw ArgErr(BsErrMsgs.fileHandler_notFile(file))
			if (!file.exists)
				throw ArgErr(BsErrMsgs.fileHandler_fileNotFound(file))
			
			fileUri	:= file.normalize.uri.toStr
			prefix  := (Uri?) directoryMappings.eachWhile |af, uri->Uri?| { fileUri.startsWith(af.uri.toStr) ? uri : null }
			if (prefix == null)
				throw BedSheetNotFoundErr(BsErrMsgs.fileHandler_fileNotMapped(file), directoryMappings.vals.map { it.osPath })
			
			matchedFile := directoryMappings[prefix]
			remaining	:= fileUri[matchedFile.uri.toStr.size..-1]
			localUrl	:= prefix + remaining.toUri
			modBaseUrl	:= (Actor.locals["web.req"] != null && httpRequest.modBase != `/`) ? httpRequest.modBase : ``
			fileHandler	:= (FileHandler) registry.serviceById(FileHandler#.qname)
			clientUrl	:= modBaseUrl.plusSlash + fileHandler.toClientUrl(localUrl)
			
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
	
	override Uri toClientUrl(Uri localUrl) {
		// add any extra 'WebMod' path segments to reach BedSheet WebMod - but only if we're part of a web request!
		(Actor.locals["web.req"] != null && httpRequest.modBase != `/`) ? httpRequest.modBase.plusSlash + localUrl : localUrl
	}
	
	override Void removeFileAsset(FileAsset fileAsset) {
		fileCache.remove(fileAsset.file)
	}
	
	override Void clear() {
		fileCache.clear
	}
	
//	override File? fromClientUrl(Uri clientUrl, Bool checked := true) {
//		if (clientUrl.host != null || !clientUrl.isRel)	// can't use Uri.isPathOnly because we allow QueryStrs and Fragments...?
//			throw ArgErr(BsErrMsgs.fileHandlerUrlNotPathOnly(clientUrl, `/css/myStyles.css`))
//		if (!clientUrl.isPathAbs)
//			throw ArgErr(BsErrMsgs.fileHandlerUrlMustStartWithSlash(clientUrl, `/css/myStyles.css`))
//		
//		// TODO: what if 2 dirs map to the same url? 
//		// match the deepest uri
//		prefix 	:= (Uri?) directoryMappings.keys.findAll { clientUrl.toStr.startsWith(it.toStr) }.sort |u1, u2 -> Int| { u1.toStr.size <=> u2.toStr.size }.last
//		if (prefix == null)
//			return null ?: (checked ? throw BedSheetNotFoundErr(BsErrMsgs.fileHandlerUrlNotMapped(clientUrl), directoryMappings.keys) : null)
//
//		// We pass 'false' to prevent Errs being thrown if the uri is a dir but doesn't end in '/'.
//		// The 'false' appends a '/' automatically - it's nicer web behaviour
//		remaining := clientUrl.getRange(prefix.path.size..-1).relTo(`/`)
//		file	  := directoryMappings[prefix].plus(remaining, false)
//
//		fileMeta  := fileCache[file]
//		
//		if (checked && !fileMeta.exists)
//			throw ArgErr(BsErrMsgs.fileHandlerUrlDoesNotExist(clientUrl, file))
//
//		return fileMeta.exists ? file : null
//	}
//
//	override Uri fromServerFile(File assetFile) {
//		fileMeta  := fileCache[assetFile]
//		if (fileMeta.isDir)
//			throw ArgErr(BsErrMsgs.fileHandlerAssetFileIsDir(assetFile))
//		if (!fileMeta.exists)
//			throw ArgErr(BsErrMsgs.fileHandlerAssetFileDoesNotExist(assetFile))
//		
//		assetUriStr := assetFile.normalize.uri.toStr
//		prefix  	:= directoryMappings.findAll |file, uri->Bool| { assetUriStr.startsWith(file.uri.toStr) }.keys.sort |u1, u2 -> Int| { u1.toStr.size <=> u2.toStr.size }.last
//		if (prefix == null)
//			throw BedSheetNotFoundErr(BsErrMsgs.fileHandlerAssetFileNotMapped(assetFile), directoryMappings.vals.map { it.osPath })
//		
//		matchedFile := directoryMappings[prefix]
//		remaining	:= assetUriStr[matchedFile.uri.toStr.size..-1]
//		assetUri	:= prefix + remaining.toUri
//		
//		return assetUri
//	}
}

