using afIoc
using afIocEnv
using afConcurrent

@NoDoc	// Advanced use only
const mixin ClientAssetCache {
	
	abstract ClientAsset? get(Uri localUrl, Bool checked := true)

	abstract ClientAsset? getOrAdd(Uri localUrl, Bool checked := true)
	
	abstract ClientAsset? getOrAddOrUpdate(Uri localUrl, |Uri->ClientAsset?| valFunc)
	
	** Removes the given asset from the internal cache.
	abstract Void remove(Uri? localUrl)
	
	** Clears the internal cache.
	abstract Void clear()
	
	** How many items in the cache.
	abstract Int size()
	
	** Hook for asset caching strategies to advise and transform URLs.
	// localUrl is needed as it's own param to give the ColdFeet aspect something to change
	@NoDoc // not sure I like this method here - but not sure where else to put it!?
	abstract Uri toClientUrl(Uri localUrl, ClientAsset asset)
}


internal const class ClientAssetCacheImpl : ClientAssetCache {
	
					** The duration between individual file checks.
					const Duration 				cacheTimeout
			private	const SynchronizedMap		assetCache
			private const ClientAssetProducer[] producers
	@Inject	private const BedSheetServer		bedServer

	new make(ClientAssetProducer[] producers, IocEnv env, ActorPools actorPools, |This|? in) {
		this.cacheTimeout = env.isProd ? 2min : 2sec
		
		in?.call(this)
		
		this.producers 	= producers
		this.assetCache = SynchronizedMap(actorPools["afBedSheet.system"]) { it.keyType = Uri#; it.valType = ClientAsset?# }
	}
	
	override ClientAsset? get(Uri localUrl, Bool checked := true) {
		assetCache.get(localUrl) ?: (
			checked ? throw ArgErr("Could not find an ClientAsset for URL `${localUrl}`") : null
		)
	}

	override ClientAsset? getOrAdd(Uri localUrl, Bool checked := true) {
		get(localUrl, false) ?: (
			producers.eachWhile { it.fromLocalUrl(localUrl, false) } ?: (
				checked ? throw ArgErr("Could not find or create an ClientAsset for URL `${localUrl}`") : null
			)
		)
	}

	override ClientAsset? getOrAddOrUpdate(Uri localUrl, |Uri->ClientAsset?| valFunc) {
		asset := (ClientAsset?) assetCache.getOrAdd(localUrl, valFunc)

		// I'm aware there could be race conditions here - but it's just a cache, so the losses are acceptable.

		// null gets added - so remove it
		if (asset == null)
			return assetCache.remove(localUrl)

		if (!asset.exists)
			return assetCache.remove(localUrl)
		
		if (asset.isModified(cacheTimeout))
			assetCache[localUrl] = valFunc(localUrl)

		return asset
	}
	
	// accept null for convenience
	override Void remove(Uri? localUrl) {
		if (localUrl != null)
			assetCache.remove(localUrl)
	}
	
	override Void clear() {
		assetCache.clear
	}

	override Int size() {
		assetCache.size
	}

	override Uri toClientUrl(Uri localUrl, ClientAsset asset) {
		// asset is used by Cold Feet so it can generate a digest 
		bedServer.toClientUrl(localUrl)		
	}
}
