using afIoc
using concurrent

// TODO: rename to ClientAsset
** Note that only metadata is cached, not the contents of the asset itself.
const abstract class CachableAsset : StaticAsset {

	@Inject
	private const AssetCache?	_assetCache 
	private const AtomicRef		_clientUrlRef		:= AtomicRef()
	private const AtomicRef		_lastCheckedRef		:= AtomicRef(DateTime.now)

	** Standard it-block ctor.
	protected new make(AssetCache? assetCache) { this._assetCache = assetCache }

	** The URL relative to the 'BedSheet' [WebMod]`web::WebMod` that corresponds to the asset resource. 
	** If your application is the ROOT WebMod then this will be the same as 'clientUrl'; bar any asset caching. 
	** If in doubt, use the 'clientUrl' instead.
	**  
	** Returns 'null' if asset doesn't exist.
	abstract Uri?		localUrl()

	** The URL that clients (e.g. web browsers) should use to access the asset resource. 
	** The 'clientUrl' contains any extra 'WebMod' path segments required to reach the 'BedSheet WebMod'.
	** It also contains path segments as provided by any asset caching strategies, such as [Cold Feet]`http://www.fantomfactory.org/pods/afColdFeet`.
	** 
	** Client URLs are designed to be used / embedded in your HTML. 
	** 
	** Note: use `BedSheetServer` should you want an absolute URL that starts with 'http://'. 
	**   
	** Returns 'null' if asset doesn't exist.
	virtual Uri?		clientUrl() {
		if (_assetCache == null)
			throw Err("${this.typeof.qname} needs to be built via IoC")
		if (_clientUrlRef.val == null)
			_clientUrlRef.val = _assetCache.toClientUrl(localUrl, this)
		return _clientUrlRef.val
	}

	** Should return an actual *live* modified time, not the cached one.
	abstract DateTime? modifiedNotCached()
	
	** Returns 'clientUrl.encode()' so it may be printed in HTML. Returns the string 'null' if the asset doesn't exist.
	override Str toStr() {
		clientUrl?.encode ?: "null"
	}
	
	virtual Bool isModified(Duration? timeout) {
		lastChecked	:= (DateTime) _lastCheckedRef.getAndSet(DateTime.now)
		if (timeout == null	|| (DateTime.now - lastChecked) > timeout)
			return modifiedNotCached.floor(1sec) > modified.floor(1sec)
		return false
	}
}
