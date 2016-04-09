using afIoc::Inject
using afIoc::RegistryMeta
using afIocConfig::ConfigSource
using web::WebReq
using concurrent

** (Service) -
** Information about the BedSheet server.  
const mixin BedSheetServer {

	** The pod that contains the initial 'AppModule'.
	abstract Pod? 	appPod()
	
	** The 'AppModule'.
	abstract Type?	appModule()	
	
	** Returns 'proj.name' from the application's pod meta, or the pod name if not defined.
	abstract Str appName()
	
	** The port BedSheet is listening to.
	abstract Int port()
	
	** The public facing domain (and scheme) used to create absolute URLs.
	** 
	** An attempt is made to get this from the requesting 'host' header,  
	** if not, then this is retrieved from the 'BedSheetConfigIds.host' config value.
	** Example:
	** 
	**   http://www.fantomfactory.org/ 
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
}

internal const class BedSheetServerImpl : BedSheetServer {

	// nullable for testing
	@Inject private const RegistryMeta?	regMeta 
	@Inject private const ConfigSource?	configSrc 
	
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
		if (webReq != null) {
			// there's a small edge case where Wisp is HTTPS but no host header is supplied, so we 
			// default to HTTP from the BedSheet host config value...
			// ...but meh, I can't be arsed to code generating the URL from the little bits of url
			try return webReq.absUri.relToAuth
			catch { /* meh - host probably wasn't a header value */ }
		}
		
		// we get host this way 'cos BedSheetServer is used (in a round about way by Pillow) in a 
		// DependencyProvider, so @Config is not available for injection
		// host is validated on startup, so we know it's okay
		return configSrc.get(BedSheetConfigIds.host, Uri#)
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
	
	private WebReq? webReq() {
		// use Actor.locals (and not reg.serviceById) to avoid Errs being thrown during testing 
		Actor.locals["web.req"]
	}
}