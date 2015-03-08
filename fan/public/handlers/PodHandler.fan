using afIoc::Inject
using afIocConfig::Config
using afBeanUtils::ArgNotFoundErr

** (Service) - A Route Handler that maps URLs to file resources inside pods. 
**
** To access a pod resource use URLs in the format:
** 
**   /<baseUrl>/<podName>/<fileName>
** 
** By default the base url is '/pods/' which means you should always be able to access the flux icon.
** 
**   /pods/icons/x256/flux.png
** 
** Change the base url in the application defaults:
** 
** pre>
** @Contribute { serviceType=ApplicationDefaults# } 
** static Void contributeAppDefaults(Configuration conf) {
**     conf[BedSheetConfigIds.podHandlerBaseUrl] = `/some/other/url/`
** }
** <pre
** 
** Set the base url to 'null' to disable the serving of pod resources.
** 
** Because pods may contain sensitive data, the entire contents of all the pods are NOT available by default. Oh no!
** 'PodHandler' has a whitelist of Regexes that specify which pod files are allowed to be served.
** If a pod resource doesn't match a regex, it doesn't get served.
** 
** By default only a handful of files with common web extensions are allowed. These include:
** 
** pre>
** .      web files: .css .htm .html .js
**      image files: .bmp .gif .ico .jpg .png
**   web font files: .eot .ttf .woff
**      other files: .txt
** <pre
** 
** To add or remove whitelist regexs, contribute to 'PodHandler':
**  
** pre>
** @Contribute { serviceType=PodHandler# } 
** static Void contributePodHandler(Configuration conf) {
**     conf.remove(".txt")                      // prevent .txt files from being served
**     conf["acmePodFiles"] = "^fan://acme/.*$" // serve all files from the acme pod
** }
** <pre
const mixin PodHandler {
	
	** The local URL under which pod resources are served.
	** 
	** Set by `BedSheetConfigIds.podHandlerBaseUrl`, defaults to '/pods/'.
	abstract Uri? baseUrl()

	** The (boring) Route handler method. 
	** Returns a 'FileAsset' as mapped from the HTTP request URL or null if not found.
	abstract FileAsset? serviceRoute(Uri remainingUrl)
		
	** Given a local URL (a simple URL relative to the WebMod), this returns a corresponding (cached) 'FileAsset'.
	** Throws 'ArgErr' if the URL is not mapped or does not exist.
	abstract FileAsset fromLocalUrl(Uri localUrl)

	** Given a pod resource file, this returns a corresponding (cached) 'FileAsset'. 
	** The URI must adhere to the 'fan://<pod>/<file>' scheme notation.
	** Throws 'ArgErr' if the URL is not mapped or does not exist.
	abstract FileAsset fromPodResource(Uri podResource)
}

internal const class PodHandlerImpl : PodHandler {

	@Config { id="afBedSheet.podHandler.baseUrl" }
	@Inject override const Uri?				baseUrl
	@Inject	private const FileAssetCache	fileCache
			private const Regex[] 			whitelistFilters
	
	new make(Regex[] filters, |This|? in) {
		this.whitelistFilters = filters

		in?.call(this)
		
		if (baseUrl == null)
			return

		if (!baseUrl.isPathOnly)
			throw BedSheetErr(BsErrMsgs.urlMustBePathOnly(baseUrl, `/pods/`))
		if (!baseUrl.isPathAbs)
			throw BedSheetErr(BsErrMsgs.urlMustStartWithSlash(baseUrl, `/pods/`))
		if (!baseUrl.isDir)
			throw BedSheetErr(BsErrMsgs.urlMustEndWithSlash(baseUrl, `/pods/`))
	}

	override FileAsset? serviceRoute(Uri remainingUrl) {
		try {
			// use pathStr to knockout any unwanted query str
			return fromPodResource(`fan://${remainingUrl.pathStr}`)
		} catch 
			// don't bother making fromLocalUrl() checked, it's too much work for a 404!
			// null means that 'Routes' didn't process the request, so it continues down the pipeline. 
			return null
	}

	override FileAsset fromLocalUrl(Uri localUrl) {
		if (baseUrl == null)
			throw Err(BsErrMsgs.podHandler_disabled)

		Utils.validateLocalUrl(localUrl, `/pods/icons/x256/flux.png`)
		if (!localUrl.toStr.startsWith(baseUrl.toStr))
			throw ArgErr(BsErrMsgs.podHandler_urlNotMapped(localUrl, baseUrl))

		remainingUrl := localUrl.relTo(baseUrl)

		return fromPodResource(`fan://${remainingUrl}`)
	}
	
	override FileAsset fromPodResource(Uri podUrl) {
		if (baseUrl == null)
			throw Err(BsErrMsgs.podHandler_disabled)

		if (podUrl.scheme != "fan")
			throw ArgErr(BsErrMsgs.podHandler_urlNotFanScheme(podUrl))

		resource := (Obj?) null
		try resource = podUrl.get
		catch throw ArgErr(BsErrMsgs.podHandler_urlDoesNotResolve(podUrl))
		if (resource isnot File)	// WTF!?
			throw ArgErr(BsErrMsgs.podHandler_urlNotFile(podUrl, resource))

		podPath := ((File) resource).uri.toStr
		if (!whitelistFilters.any { it.matches(podPath) })
			throw ArgNotFoundErr(BsErrMsgs.podHandler_notInWhitelist(podPath), whitelistFilters)
		
		return fileCache.getOrAddOrUpdate(resource) |File file->FileAsset| {
			if (!file.exists)
				throw ArgErr(BsErrMsgs.fileNotFound(file))
			
			host		:= file.uri.host.toUri.plusSlash
			path		:= file.uri.pathOnly.relTo(`/`)
			localUrl	:= baseUrl + host + path 
			clientUrl	:= fileCache.toClientUrl(localUrl, file)

			return FileAsset(file, localUrl, clientUrl)
		}
	}	
}
