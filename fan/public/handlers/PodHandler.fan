using afIoc::Inject
using afIocConfig::Config

** (Service) - A Request Handler that maps URIs to file resources inside pods. 
**
** pre>
** @Contribute { serviceType=Routes# }
** static Void contributeRoutes(Configuration conf) {
**   ...
**   conf.add(Route(`/pods/***`, PodHandler#service))
**   ...
** }
** <pre
** 
** Now a request to '/pods/icons/x256/flux.png' should return just that! 
const mixin PodHandler {

	** The Route handler method. 
	** Returns a 'FileAsset' as mapped from the HTTP request URL or null if not found.
	@NoDoc	// boring route handler method
	abstract FileAsset? serviceRoute(Uri remainingUrl)
		
	** Given a local URL (a simple URL relative to the WebMod), this returns a corresponding (cached) 'FileAsset'.
	** Throws 'ArgErr' if the URL is not mapped.
	abstract FileAsset fromLocalUrl(Uri localUrl)

	** Given a pod resource file, this returns a corresponding (cached) 'FileAsset'. 
	** The URI must adhere to the 'fan://<pod>/<file>' scheme notation.
	** Throws 'ArgErr' if the pod resource is not mapped or does not exist
	abstract FileAsset fromPodResource(Uri podResource)
}

internal const class PodHandlerImpl : PodHandler {

	@Config { id="afBedSheet.podHandler.url" }
	@Inject private const Uri				podHandlerUrl
	@Inject	private const FileAssetCache	fileCache
		
	new make(|This|? in) { 
		in?.call(this) 
		// FIXME: validate pod url
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
		if (localUrl.host != null || !localUrl.isRel)	// can't use Uri.isPathOnly because we allow QueryStrs and Fragments...?
			throw ArgErr(BsErrMsgs.urlMustBePathOnly(localUrl, `/css/myStyles.css`))
		if (!localUrl.isPathAbs)
			throw ArgErr(BsErrMsgs.urlMustStartWithSlash(localUrl, `/css/myStyles.css`))
		if (!localUrl.toStr.startsWith(podHandlerUrl.toStr))
			throw ArgErr(BsErrMsgs.podHandler_urlNotMapped(localUrl, podHandlerUrl))

		remainingUrl := localUrl.relTo(podHandlerUrl)
		
		return fromPodResource(`fan://${remainingUrl}`)
	}
	
	override FileAsset fromPodResource(Uri podUrl) {
		if (podUrl.scheme != "fan")
			throw ArgErr()
		if (podUrl.host == null)
			throw ArgErr()
		
		resource := (Obj?) null
		try 	resource = (podUrl).get
		catch	throw ArgErr(podUrl.toStr)
		if (resource isnot File)
			throw ArgErr("Uri `${podUrl}` does not resolve to a File")

		return fileCache.getOrAddOrUpdate(resource) |File file->FileAsset| {
			if (!file.exists)
				throw ArgErr(BsErrMsgs.fileNotFound(file))
			
			localUrl	:= podHandlerUrl + file.uri.pathOnly.relTo(`/`)
			clientUrl	:= fileCache.toClientUrl(localUrl, file)

			return FileAsset {
				it.file 		= file
				it.exists		= file.exists
				it.modified		= file.modified?.floor(1sec)
				it.size			= file.size
				it.etag			= it.exists ? "${it.size?.toHex}-${it.modified?.ticks?.toHex}" : null
				it.localUrl		= localUrl
				it.clientUrl	= clientUrl
			}
		}	
	}
}
