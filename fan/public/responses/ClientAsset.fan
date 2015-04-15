using concurrent

** (Response Object) - 
** An asset that corresponds to and may be uniquely identified by a client URL.
** 
** Client assets generate a client URL that may be used by clients (e.g. internet browsers) to retrieve the asset.
** Client URLs are subject to change as per asset caching strategies such as [Cold Feet]`http://www.fantomfactory.org/pods/afColdFeet`, 
** the results of which are cached for 2 minutes in production or 2 seconds otherwise.
** 
** Generally 'ClientAssets' are acquired from the 'FileHander' and 'PodHander' services and used to embed client URLs in web pages.
** 
**   url := fileHandler.fromLocalUrl(`/images/fanny.jpg`).clientUrl.encode
** 
const abstract class ClientAsset : Asset {

	private const ClientAssetCache?	_assetCache 
	private const AtomicRef			_clientUrlRef		:= AtomicRef()
	private const AtomicRef			_lastCheckedRef		:= AtomicRef(DateTime.now)

	** Standard it-block ctor.
	protected new make(ClientAssetCache? assetCache) { this._assetCache = assetCache }

	** The URL relative to the 'BedSheet' [WebMod]`web::WebMod` that corresponds to the asset resource. 
	** If your application is the ROOT WebMod then this will be the same as 'clientUrl'; bar any asset caching. 
	** If in doubt, use the 'clientUrl' instead.
	**  
	** Returns 'null' if asset doesn't exist.
	abstract Uri?		localUrl()

	** Should return an actual *live* modified time, not the cached one.
	abstract DateTime? modifiedNotCached()

	** The URL that clients (e.g. web browsers) should use to access the asset resource. 
	** The 'clientUrl' contains any extra 'WebMod' path segments required to reach the 'BedSheet WebMod'.
	** It also contains path segments as provided by any asset caching strategies, such as [Cold Feet]`http://www.fantomfactory.org/pods/afColdFeet`.
	** 
	** Client URLs are designed to be used / embedded in your HTML and therefore are relative to the host and start with a '/'. 
	** 
	** They are  use `BedSheetServer` should you want an absolute URL that starts with 'http://'. 
	** 
	** Returns 'null' if asset doesn't exist.
	** 
	** Override 'clientUrl()' if you don't wish the client url to be altered by asset caching strategies like [Cold Feet]`http://www.fantomfactory.org/pods/afColdFeet`. 
	virtual Uri?		clientUrl() {
		if (_assetCache == null)
			throw Err("${this.typeof.qname} needs to be built via IoC")
		if (_clientUrlRef.val == null)
			_clientUrlRef.val = _assetCache.toClientUrl(localUrl, this)
		return _clientUrlRef.val
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
	
	virtual Bool isModified(Duration? timeout) {
		lastChecked	:= (DateTime) _lastCheckedRef.getAndSet(DateTime.now)
		if (timeout == null	|| (DateTime.now - lastChecked) > timeout)
			return modifiedNotCached.floor(1sec) > modified.floor(1sec)
		return false
	}
}
