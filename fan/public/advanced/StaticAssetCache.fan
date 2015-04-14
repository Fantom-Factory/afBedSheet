using afIoc
using afIocEnv
using afConcurrent

@NoDoc	// Advanced use only
const mixin AssetCache {
	
	abstract CachableAsset getOrAddOrUpdate(Uri key, |Uri->CachableAsset| valFunc)
	
	** Removes the given asset from the internal cache.
	abstract Void remove(Uri? key)
	
	** Clears the internal cache.
	abstract Void clear()
	
	** How many items in the cache.
	abstract Int size()
	
	** Hook for asset caching strategies to advise and transform URLs.
	@NoDoc // not sure I like this method here - but not sure where else to put it!?
	abstract Uri toClientUrl(Uri localUrl, CachableAsset asset)
}


internal const class AssetCacheImpl : AssetCache {
	
					** The duration between individual file checks.
					const Duration 			cacheTimeout
			private	const SynchronizedMap	assetCache
	@Inject	private const BedSheetServer	bedServer

	new make(Uri:File dirMappings, IocEnv env, ActorPools actorPools, |This|? in) {
		this.cacheTimeout = env.isProd ? 2min : 2sec
		
		in?.call(this)
		
		this.assetCache = SynchronizedMap(actorPools["afBedSheet.system"]) { it.keyType = Uri#; it.valType = CachableAsset# }
	}
	
	override CachableAsset getOrAddOrUpdate(Uri key, |Uri->CachableAsset| valFunc) {
		asset := (CachableAsset) assetCache.getOrAdd(key, valFunc)

		// I'm aware there could be race conditions here - but it's just a cache, so the losses are acceptable.
		if (!asset.exists)
			return assetCache.remove(key)
		
		if (asset.isModified(cacheTimeout))
			assetCache[key] = valFunc(key)

		return asset
	}
	
	override Void remove(Uri? key) {
		if (key != null)
			assetCache.remove(key)
	}
	
	override Void clear() {
		assetCache.clear
	}

	override Int size() {
		assetCache.size
	}

	override Uri toClientUrl(Uri localUrl, CachableAsset asset) {
		// asset is used by Cold Feet so it can generate a digest 
		bedServer.toClientUrl(localUrl)		
	}
}
