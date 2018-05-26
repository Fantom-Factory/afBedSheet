using afIoc
using concurrent

** (Response Object) - 
** An asset that is uniquely identified by a client URL.
** 
** A 'ClientAsset' corresponds to a client URL that may be used by clients (e.g. internet browsers) to retrieve the asset.
** 
** Generally 'ClientAssets' are acquired from the 'FileHander' and 'PodHander' services and used to embed client URLs in web pages.
** 
**   syntax: fantom
**   urlStr := fileHandler.fromLocalUrl(`/images/fanny.jpg`).clientUrl.encode
** 
** The URLs generated by 'ClientAssets' may be automatically transformed by asset caching strategies such as 
** [Cold Feet]`pod:afColdFeet`. 
** As such, 'ClientAsset' instances are cached and automatically updated should the underlying asset be modified.
** To prevent needless polling of the file system, assets are checked for modification every 2 minutes in production 
** or 2 seconds otherwise.
** 
** Custom Client Assets
** ====================
** If you want to serve up assets from a database or other source, subclass 'ClientAsset' to create your own custom implementation. 
** Custom 'ClientAsset' instances should created by a `ClientAssetProducer` and contributed to the 'ClientAssetProducers' service. 
** This ensures your custom assets will automatically adopt any asset caching strategy set by Cold Feet.
const abstract class ClientAsset : Asset {

	@Inject
	private const ClientAssetCache?	_assetCache 
	@Inject
	private const BedSheetServer?	_bedServer
	private const AtomicRef			_clientUrlRef		:= AtomicRef()
	private const AtomicRef			_lastCheckedRef		:= AtomicRef(DateTime.now)

	** Autobuild 'ClientAsset' instances with IoC.
	@NoDoc
	protected new make(|This|? in) { in?.call(this) }

	** The URL relative to the 'BedSheet' [WebMod]`web::WebMod` that corresponds to the asset resource. 
	** If your application is the ROOT WebMod then this will be the same as 'clientUrl'; bar any asset caching. 
	** If in doubt, use the 'clientUrl' instead.
	**  
	** Returns 'null' if asset doesn't exist.
	abstract Uri? localUrl()

	** The URL that clients (e.g. web browsers) should use to access the asset resource. 
	** The 'clientUrl' contains any extra 'WebMod' path segments required to reach the 'BedSheet WebMod'.
	** It also contains path segments as provided by any asset caching strategies, such as [Cold Feet]`pod:afColdFeet`.
	** 
	** Client URLs are designed to be used / embedded in your HTML and therefore are relative to the host and start with a '/'. 
	** 
	** Returns 'null' if asset doesn't exist.
	** 
	** Subclasses should override 'clientUrl()' if they **do not** wish the client URL to be transformed by asset caching strategies like [Cold Feet]`http://eggbox.fantomfactory.org/pods/afColdFeet`. 
	virtual Uri? clientUrl() {
		if (_assetCache == null)	// assetCache is nullable for FileAsset legacy code
			throw Err("${this.typeof.qname} needs to be built via IoC")
		localUrl := localUrl
		if (localUrl == null)
			return null
		if (_clientUrlRef.val == null)
			_clientUrlRef.val = _assetCache.toClientUrl(localUrl, this)
		return _clientUrlRef.val
	}
	
	** Returns an absolute URL (for example, one that starts with 'http://...') using [BedSheetServer.toAbsoluteUrl()]`BedSheetServer.toAbsoluteUrl`.
	** 
	** Returns 'null' if asset doesn't exist.
	virtual Uri? clientUrlAbs() {
		_bedServer.toAbsoluteUrl(clientUrl)
	}
	
	@NoDoc
	override Int hash() {
		localUrl ?: super.hash
	}
	
	@NoDoc
	override Bool equals(Obj? obj) {
		localUrl != null
			? localUrl == (obj as ClientAsset)?.localUrl
			: super.equals(obj)
	}

	** Returns 'clientUrl.encode()' so it may be printed in HTML. Returns the string 'null' if the asset doesn't exist.
	override Str toStr() {
		clientUrl?.encode ?: super.toStr
	}
	
	@NoDoc
	virtual Bool isModified(Duration? timeout) {
		lastChecked	:= (DateTime) _lastCheckedRef.getAndSet(DateTime.now)
		actualModified := actualModified
		if (actualModified == null)
			return true
		
		if (timeout == null	|| (DateTime.now - lastChecked) > timeout)
			return actualModified.floor(1sec) > modified.floor(1sec)
		return false
	}
	
	** If the asset contents are liable to change behind the scenes, 
	** like the contents of a file may, then this should return the latest
	** calculated modified date. 
	** 
	** May return 'null' if not known.
	@NoDoc	// used by isModified()
	virtual DateTime? actualModified() {
		modified
	}
}
