using afIoc
using afIocEnv
using afConcurrent::ActorPools
using afConcurrent::SynchronizedMap

@NoDoc	// Advanced use only
const mixin ClientAssetCache {
	
	** Returns a cached 'ClientAsset' from the given 'localUrl'. 
	** If the asset doesn't exist, or has been modified since being cached (see `Asset.isModified`) then 
	** all 'AssetProducers' are polled to return a fresh instance.
	abstract ClientAsset? getAndUpdateOrProduce(Uri localUrl)

	** Returns a cached 'ClientAsset' from the given 'localUrl'. 
	** If the asset doesn't exist, or has been modified since being cached (see `Asset.isModified`) then 
	** a fresh instance is created using the given func.
	** 
	** This is generally called by 'AssetProducers' themselves in a 'getOrMake()' capacity. 
	abstract ClientAsset? getAndUpdateOrMake(Uri localUrl, |Uri->ClientAsset?| makeFunc)

	** Removes the given asset from the internal cache.
	** Does nothing if 'localUrl' is 'null'.
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


@NoDoc // so ColdFeet may override it
const class ClientAssetCacheImpl : ClientAssetCache {
	
					** The duration between individual file checks.
					const Duration 				cacheTimeout
			private	const SynchronizedMap		assetCache
	@Inject private const ClientAssetProducers	assetProducers
	@Inject	private const BedSheetServer		bedServer

	new make(IocEnv env, ActorPools actorPools, |This|? in) {
		this.cacheTimeout = env.isProd ? 2min : 5sec
		this.assetCache = SynchronizedMap(actorPools["afBedSheet.system"]) { it.keyType = Uri#; it.valType = ClientAsset?# }		
		in?.call(this)
	}
	
	override ClientAsset? getAndUpdateOrProduce(Uri localUrl) {
		getAndUpdateOrMake(localUrl) {
			assetProducers.produceAsset(localUrl)
		}
	}

	override ClientAsset? getAndUpdateOrMake(Uri localUrl, |Uri->ClientAsset?| makeFunc) {
		// I'm aware there could be race conditions here - but it's just a cache, so the losses are acceptable.
		asset := (ClientAsset?) assetCache.get(localUrl)
		
		if (asset != null) {
			if (!asset.exists)
				assetCache.remove(localUrl)

			else if (asset.isModified(cacheTimeout)) {
				// remove in preparation of creating a new one
				assetCache.remove(localUrl)
				asset = null
			}
		}
		
		// if either the asset was modified, or wasn't cached
		if (asset == null) {
			asset = makeFunc(localUrl)
			
			if (asset != null && asset.exists)
				assetCache[localUrl] = asset
		}
		
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
