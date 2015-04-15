using afIoc::Inject
using afIoc::Registry
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
** 
** 
** Serve Fantom Code
** =================
** Fantom compiles all classes in a pod annotated with the '@Js' facet into a Javascript file that is saved in the pod.
** These pod '.js' files can then be served up with 'PodHandler' allowing you execute Fantom code in the browser.
** 
** Here is an example that calls 'alert()' via Fantom's DOM pod. To run, just serve the example as static HTML:
** 
** pre>
** syntax: html
** 
** <!DOCTYPE html>
** <html>
** <head>
**     <script type="text/javascript" src="/pods/sys/sys.js"></script>
**     <script type="text/javascript" src="/pods/gfx/gfx.js"></script>
**     <script type="text/javascript" src="/pods/web/web.js"></script>
**     <script type="text/javascript" src="/pods/dom/dom.js"></script>
** </head>
** <body>
**     <h1>Old Skool Example</h1>
** 
**     <script type="text/javascript">
**         fan.dom.Win.cur().alert("Hello Mum!");
**     </script>
** </body>
** </html>
** <pre
** 
** Note that the order in which the pod '.js' files are listed is very important; each pod's dependencies must be listed before the pod itself.
** 
** Fantom code may also be executed via the [web::WebUtil.jsMain()]`web::WebUtil.jsMain` method.
** 
** A much cleaner way injecting Fantom code is to use the [Duvet library]`http://www.fantomfactory.org/pods/afDuvet` which uses 
** [RequireJS]`http://requirejs.org/docs/api.html` to wrap up the Fantom code as dependency managed Javascript modules. 
** 
** 
** 
** Resource Whitelist
** ==================
** Because pods may contain sensitive data, the entire contents of all the pods are NOT available by default. Oh no!
** 'PodHandler' has a whitelist of Regexes that specify which pod files are allowed to be served.
** If a pod resource doesn't match a regex, it doesn't get served.
** 
** By default only a handful of files with common web extensions are allowed. These include:
** 
** pre>
** .      web files: .css .htm .html .js .xhtml
**      image files: .bmp .gif .ico .jpg .png
**   web font files: .eot .otf .svg .ttf .woff
**      other files: .csv .txt .xml
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
	abstract ClientAsset? serviceRoute(Uri remainingUrl)
		
	** Given a local URL (a simple URL relative to the WebMod), this returns a corresponding (cached) 'FileAsset'.
	** Throws 'ArgErr' if the URL is not mapped or does not exist.
	abstract ClientAsset fromLocalUrl(Uri localUrl)

	** Given a pod resource file, this returns a corresponding (cached) 'FileAsset'. 
	** The URI must adhere to the 'fan://<pod>/<file>' scheme notation.
	** Throws 'ArgErr' if the URL is not mapped or does not exist.
	abstract ClientAsset fromPodResource(Uri podResource)
}

internal const class PodHandlerImpl : PodHandler {

	@Config { id="afBedSheet.podHandler.baseUrl" }
	@Inject override const Uri?				baseUrl
	@Inject	private const ClientAssetCache	assetCache
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

	override ClientAsset? serviceRoute(Uri remainingUrl) {
		try {
			// use pathStr to knockout any unwanted query str
			return fromPodResource(`fan://${remainingUrl.pathStr}`)
		} catch 
			// don't bother making fromLocalUrl() checked, it's too much work for a 404!
			// null means that 'Routes' didn't process the request, so it continues down the pipeline. 
			return null
	}

	override ClientAsset fromLocalUrl(Uri localUrl) {
		if (baseUrl == null)
			throw Err(BsErrMsgs.podHandler_disabled)

		Utils.validateLocalUrl(localUrl, `/pods/icons/x256/flux.png`)
		if (!localUrl.toStr.startsWith(baseUrl.toStr))
			throw ArgErr(BsErrMsgs.podHandler_urlNotMapped(localUrl, baseUrl))

		remainingUrl := localUrl.relTo(baseUrl)

		return fromPodResource(`fan://${remainingUrl}`)
	}
	
	override ClientAsset fromPodResource(Uri podUrl) {
		if (baseUrl == null)
			throw Err(BsErrMsgs.podHandler_disabled)

		if (podUrl.scheme != "fan")
			throw ArgErr(BsErrMsgs.podHandler_urlNotFanScheme(podUrl))

		resource := (Obj?) null
		try resource = podUrl.get
		catch throw ArgErr(BsErrMsgs.podHandler_urlDoesNotResolve(podUrl))
		if (resource isnot File)	// WTF!?
			throw ArgErr(BsErrMsgs.podHandler_urlNotFile(podUrl, resource))

		file	:= (File) resource
		podPath := file.uri.toStr
		if (!whitelistFilters.any { it.matches(podPath) })
			throw ArgNotFoundErr(BsErrMsgs.podHandler_notInWhitelist(podPath), whitelistFilters)
		
		host		:= file.uri.host.toUri.plusSlash
		path		:= file.uri.pathOnly.relTo(`/`)
		localUrl	:= baseUrl + host + path

		return assetCache.getOrAddOrUpdate(localUrl) |Uri key->ClientAsset| {
			if (!file.exists)
				throw ArgErr(BsErrMsgs.fileNotFound(file))
			
			return FileAsset.makeCachable(localUrl, file, assetCache)
		}
	}	
}
