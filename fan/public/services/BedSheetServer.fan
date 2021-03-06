using afIoc::Inject
using afIoc::RegistryMeta
using afIocConfig::ConfigSource
using web::WebReq
using web::WebUtil
using concurrent

** (Service) -
** Information about the BedSheet server.  
const mixin BedSheetServer {

	** The pod that contains the initial 'AppModule'.
	abstract Pod? 	appPod()
	
	** The 'AppModule'.
	abstract Type?	appModule()	
	
	** Returns 'pod.dis' (or 'proj.name'if not found) from the application's pod meta, or the pod name if neither are defined.
	abstract Str appName()
	
	** The port BedSheet is listening to.
	abstract Int port()
	
	** The public facing domain (including scheme & port) used to create absolute URLs.
	** 
	** If set, this is taken from the `BedSheetConfigIds.host` config value.
	** 
	** If not, then an attempt is made to get this from the HTTP request via the following (in order):
	** 
	**  1. The 'Forwarded' HTTP header - see [RFC 7239]`https://tools.ietf.org/html/rfc7239`  
	**  2. The 'X-Forwarded-XXXX' HTTP headers
	**  3. The 'host' HTTP header  
	**
	** See `HttpRequest.host` for details. 
	** 
	** If all fails then 'http://localhost:${port}/' is returned.
	** 
	** Example:
	** 
	**   syntax: fantom
	**   bedSheetServer.host() // --> http://www.fantomfactory.org/ 
	abstract Uri host()
	
	** The Registry options BedSheet was started with.
	abstract [Str:Obj] 	options()
	
	** Returns a list of modules loaded by this BedSheet's IoC
	abstract Type[] moduleTypes()
	
	** Returns a unique list of pods that contain modules loaded by this BedSheet's IoC.
	**  
	** Useful for gaining a list of pods used in an application, should you wish to *scan* for
	** classes. 
	abstract Pod[] modulePods()
	
	** The request path to this BedSheet 'WebMod'. 
	** Only really relevant should BedSheet be started in a [RouteMod]`webmod::RouteMod`.
	** 
	** Starts and ends with a '/'. Example, '`/pub/`'
	** 
	** Returns '`/`' should BedSheet be the root 'WebMod' (the usual case).
	** 
	** @see `web::WebReq.modBase`
	abstract Uri path()
	
	** Prepends any extra 'WebMod' path info to the given URL so it may be used by clients and browsers.
	** The given 'WebMod' local URL should be relative to the BedSheet 'WebMod' and may, or may not, start with a '/'.
	abstract Uri toClientUrl(Uri localUrl)
	
	** Creates an absolute URL for public use; including scheme and authority (host).
	** The given 'clientUrl' should be relative to the host and start with a '/'.
	**
	** The scheme and authority in the generated URL are taken from the 'host()' method. 
	abstract Uri toAbsoluteUrl(Uri clientUrl)
	
	** Returns a 'ClientAsset' for the given local URL.
	** Throws an Err if 'checked' and a ClientAsset could not be produced.
	abstract ClientAsset? getClientAsset(Uri localUrl, Bool checked := true)
}

internal const class BedSheetServerImpl : BedSheetServer {

	// nullable for testing
	@Inject private const RegistryMeta?			regMeta 
	@Inject private const ConfigSource?			configSrc 
	@Inject private const |->ClientAssetCache|?	assetCache	// assetCache uses BedSheeetServer!
	
	new make(|This|in) { in(this) }
	
	override Pod? appPod() {
		regMeta[BsConstants.meta_appPod]
	}
	
	override Type? appModule() {
		regMeta[BsConstants.meta_appModule]
	}
	
	override Str appName() {
		regMeta[BsConstants.meta_appName]
	}
	
	override Int port() {
		regMeta[BsConstants.meta_appPort]
	}
	
	override [Str:Obj] options() {
		regMeta.options
	}
	
	override Type[] moduleTypes() {
		regMeta.moduleTypes
	}
	
	override Pod[] modulePods() {
		regMeta.modulePods
	}
	
	override Uri path() {
		// default to root for testing
		webReq?.modBase ?: `/`
	}

	override Uri host() {
		// we get host this way 'cos BedSheetServer is used (in a round about way by Pillow) in a 
		// DependencyProvider, so @Config is not available for injection
		// host is validated on startup, so we know it's okay
		bedSheetHost := (Uri) configSrc.get(BedSheetConfigIds.host, Uri#)
		
		// if someone has gone to the trouble of setting a config value - then let's use it
		// as it's probably the normalised host of multiple sites
		if (bedSheetHost.host != "localhost")
			return bedSheetHost
		
		// otherwise, lets parse the web req
		webReq := webReq
		if (webReq != null) {
			host := HttpRequestImpl.hostViaHeaders(webReq.headers)
			
			if (host != null) {
				// hostViaHeaders is not guaranteed to return a scheme
				if (host.scheme == null)
					host = `http:${host}`
				return host
			}
		}

		return bedSheetHost
	}

	override Uri toClientUrl(Uri localUrl) {
		// if we stop throwing an Err here, then we need to update ColdFeet
		if (localUrl.host != null || !localUrl.isRel)	// can't use Uri.isPathOnly because we allow QueryStrs and Fragments...?
			throw ArgErr(BsErrMsgs.urlMustBePathOnly(localUrl, `/css/myStyles.css`))
		return path + localUrl.relTo(`/`)
	}

	override Uri toAbsoluteUrl(Uri clientUrl) {
		Utils.validateLocalUrl(clientUrl, `/css/myStyles.css`)
		return host + clientUrl.relTo(`/`)
	}
	
	override ClientAsset? getClientAsset(Uri localUrl, Bool checked := true) {
		assetCache().getAndUpdateOrProduce(localUrl) ?: (checked ? throw Err("Could not produce a ClientAsset for: ${localUrl}") : null)
	}
	
	private WebReq? webReq() {
		// use Actor.locals (and not reg.serviceById) to avoid Errs being thrown during testing 
		Actor.locals["web.req"]
	}
}