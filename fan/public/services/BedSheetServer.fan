using afIoc::Inject
using afIoc::Registry
using afIoc::RegistryMeta
using afIocConfig::IocConfigSource
using web::WebReq
using concurrent

** (Service) -
** Information about the BedSheet server.  
const mixin BedSheetServer {

	** The pod that contains the initial 'AppModule'.
	abstract Pod? 	appPod()
	
	** The 'AppModule'.
	abstract Type?	appModule()	
	
	** Returns 'proj.name' from the application's pod meta, or "Unknown" if no pod was found.
	virtual Str appName() {
		appPod?.meta?.get("proj.name") ?: "Unknown"
	}
	
	** The port BedSheet is listening to.
	abstract Int port()
	
	** The public facing domain used to create absolute URLs.
	** This is set by 'BedSheetConfigIds.host'. 
	abstract Uri host()
	
	** The options BedSheet was started with
	abstract [Str:Obj] 	options()
	
	** Returns a list of modules loaded by this BedSheet's IoC
	abstract Type[] moduleTypes()
	
	** Returns a unique list of pods that contain modules loaded by this BedSheet's IoC.
	**  
	** Useful for gaining a list of pods used in an application, should you wish to *scan* for
	** classes. 
	abstract Pod[] modulePods()
	
	** The request path to this BedSheet 'WebMod'. 
	** Only really relevant should BedSheet be started in a [RouteMod]`web::RouteMod`.
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
	
	** Creates an absolute URL for public use; includes scheme, authority and path to this 'WebMod'.
	** The given 'WebMod' local URL should be relative to the BedSheet 'WebMod' and may, or may not, start with a '/'.
	** 
	** The scheme, if 'null', defaults to whatever was set in `BedSheetConfigIds.host`.
	abstract Uri toAbsoluteUrl(Uri localUrl, Str? scheme := null)
}

internal const class BedSheetServerImpl : BedSheetServer {

	// nullable for testing
	@Inject private const RegistryMeta?		regMeta 
	@Inject private const IocConfigSource?	configSrc 
	
	new make(|This|in) { in(this) }
	
	override Pod? appPod() {
		bedSheetMeta.appPod
	}
	
	override Type? appModule() {
		bedSheetMeta.appModule
	}
	
	override Int port() {
		bedSheetMeta.port
	}
	
	override [Str:Obj] options() {
		bedSheetMeta.options
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
		// DependencyProvider, so @Config is not available for injection then
		// host is validated on startup, so we know it's okay
		configSrc.get(BedSheetConfigIds.host, Uri#)
	}
	
	override Uri toClientUrl(Uri localUrl) {
		path + localUrl.relTo(`/`)
	}
	
	override Uri toAbsoluteUrl(Uri localUrl, Str? scheme := null) {
		absUrl := (scheme == null) ? host : (scheme + host.toStr[host.scheme.size..-1]).toUri
		return absUrl + toClientUrl(localUrl).relTo(`/`)
	}
	
	private WebReq? webReq() {
		Actor.locals["web.req"]
	}

	private BedSheetMetaData bedSheetMeta() {
		if (!regMeta.options.containsKey("afBedSheet.metaData"))
			throw BedSheetErr(BsErrMsgs.bedSheetMetaDataNotInOptions)
		return regMeta.options["afBedSheet.metaData"] 
	}
	
	static Void main() {
		scheme := (Str?) null
		host   := `http://example.com/`
		path   := `/`
		relUrl := `/index.html`
		
		absUrl := (scheme == null) ? host : (scheme + host.toStr[host.scheme.size..-1]).toUri
		a := absUrl + path.relTo(`/`) + relUrl.relTo(`/`)
		echo(a)
	}
}