using afIoc::Inject
using afIoc::Scope
using afIocConfig::Config
using afBeanUtils::ArgNotFoundErr

** (Service) - 
** A 'ClientAssetProducer' that maps URLs to file resources inside pods. 
**
** To access a pod resource use URLs in the format:
** 
**   /<baseUrl>/<podName>/<fileName>
** 
** By default the 'baseUrl' is '/pod/' which means you should always be able to access the flux icon.
** 
**   /pod/icons/x256/flux.png
** 
** Change the base url in the application defaults:
** 
** pre>
** syntax: fantom
** @Contribute { serviceType=ApplicationDefaults# } 
** Void contributeAppDefaults(Configuration config) {
**     config[BedSheetConfigIds.podHandlerBaseUrl] = `/some/other/url/`
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
**     <script type="text/javascript" src="/pod/sys/sys.js"></script>
**     <script type="text/javascript" src="/pod/gfx/gfx.js"></script>
**     <script type="text/javascript" src="/pod/web/web.js"></script>
**     <script type="text/javascript" src="/pod/dom/dom.js"></script>
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
** .      web files: .css .htm .html .js .xhtml .js.map
**      image files: .bmp .gif .ico .jpg .png
**      sound files: .mp3 .ogg .wav .opus
**   web font files: .eot .otf .svg .ttf .woff
**      other files: .csv .txt .xml
** <pre
** 
** To add or remove whitelist regexs, contribute to 'PodHandler':
**  
** pre>
** syntax: fantom
** @Contribute { serviceType=PodHandler# } 
** static Void contributePodHandler(Configuration conf) {
**     conf.remove(".txt")                      // prevent .txt files from being served
**     conf["acmePodFiles"] = "^fan://acme/.*$" // serve all files from the acme pod
** }
** <pre
const mixin PodHandler : ClientAssetProducer {
	
	** The local URL under which pod resources are served.
	** 
	** Set by `BedSheetConfigIds.podHandlerBaseUrl`, defaults to '/pods/'.
	abstract Uri? baseUrl()

	** Given a local URL (a simple URL relative to the WebMod), this returns a corresponding (cached) 'FileAsset'.
	** Throws 'ArgErr' if the URL is not mapped or does not exist.
	abstract ClientAsset? fromLocalUrl(Uri localUrl, Bool checked := true)

	** Given a pod resource file, this returns a corresponding (cached) 'FileAsset'. 
	** The URI must adhere to the 'fan://<pod>/<file>' scheme notation.
	** Throws 'ArgErr' if the URL is not mapped or does not exist.
	abstract ClientAsset? fromPodResource(Uri podResource, Bool checked := true)
}

internal const class PodHandlerImpl : PodHandler {

	@Config { id="afBedSheet.podHandler.baseUrl" }
	@Inject override const Uri?					baseUrl
	@Inject	private const |->ClientAssetCache|	assetCache
	@Inject	private const Scope					scope
			private const Regex[] 				whitelistFilters
	
	new make(Regex[] filters, |This|? in) {
		this.whitelistFilters = filters

		in?.call(this)
		
		if (baseUrl == null)
			return

		if (!baseUrl.isPathOnly)
			throw BedSheetErr(BsErrMsgs.urlMustBePathOnly(baseUrl, `/pod/`))
		if (!baseUrl.isPathAbs)
			throw BedSheetErr(BsErrMsgs.urlMustStartWithSlash(baseUrl, `/pod/`))
		if (!baseUrl.isDir)
			throw BedSheetErr(BsErrMsgs.urlMustEndWithSlash(baseUrl, `/pod/`))
	}

	override ClientAsset? produceAsset(Uri localUrl) {
		_fromLocalUrl(localUrl, false, false)
	}

	override ClientAsset? fromLocalUrl(Uri localUrl, Bool checked := true) {
		_fromLocalUrl(localUrl, checked, true)
	}
	
	override ClientAsset? fromPodResource(Uri podUrl, Bool checked := true) {
		_fromPodResource(podUrl, checked, true)
	}	

	ClientAsset? _fromLocalUrl(Uri localUrl, Bool checked, Bool cache) {
		if (baseUrl == null)
			if (checked) throw Err(BsErrMsgs.podHandler_disabled)
			else return null

		Utils.validateLocalUrl(localUrl, `/pod/icons/x256/flux.png`)
		if (!localUrl.toStr.startsWith(baseUrl.toStr))
			if (checked) throw ArgErr(BsErrMsgs.podHandler_urlNotMapped(localUrl, baseUrl))
			else return null

		remainingUrl := localUrl.relTo(baseUrl)

		return fromPodResource(`fan://${remainingUrl}`, checked)
	}
	
	ClientAsset? _fromPodResource(Uri podUrl, Bool checked, Bool cache) {
		if (baseUrl == null)
			if (checked) throw Err(BsErrMsgs.podHandler_disabled)
			else return null
 
		if (podUrl.scheme != "fan")
			if (checked) throw ArgErr(BsErrMsgs.podHandler_urlNotFanScheme(podUrl))
			else return null

		resource := (Obj?) null
		try resource = podUrl.get
		catch 
			if (checked) throw ArgErr(BsErrMsgs.podHandler_urlDoesNotResolve(podUrl))
			else return null

		if (resource isnot File)	// WTF!?
			if (checked) throw ArgErr(BsErrMsgs.podHandler_urlNotFile(podUrl, resource))
			else return null

		file	:= (File) resource
		podPath := file.uri.toStr
		if (!whitelistFilters.any { it.matches(podPath) })
			if (checked) throw ArgNotFoundErr(BsErrMsgs.podHandler_notInWhitelist(podPath), whitelistFilters)
			else return null
		
		host		:= file.uri.host.toUri.plusSlash
		path		:= file.uri.pathOnly.relTo(`/`)
		localUrl	:= baseUrl + host + path

		makeFunc := |Uri key->ClientAsset?| {
			if (!file.exists)
				if (checked) throw ArgErr(BsErrMsgs.fileNotFound(file))
				else return null
			
			return scope.build(FileAsset#, [localUrl, file])
		}
		
		return cache ? assetCache().getAndUpdateOrMake(localUrl, makeFunc) : makeFunc(localUrl) 
	}	
}
