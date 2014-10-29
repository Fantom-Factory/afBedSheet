using afIoc
using afIocEnv
using afConcurrent
using concurrent

@NoDoc	// Advanced use only
const mixin FileAssetCache {
	
	abstract FileAsset? getOrAddOrUpdate(File key, |File->Obj?| valFunc)
	
	** Removes the given 'FileAsset' from the internal cache.
	abstract Void remove(FileAsset fileAsset)
	
	** Clears the internal 'FileAsset' cache.
	abstract Void clear()
	
	** Hook for asset caching strategies to advise and transform URLs.
	abstract Uri toClientUrl(Uri localUrl, File file)
}

internal const class FileAssetCacheImpl : FileAssetCache {
	
					** The duration between individual file checks.
					const Duration 				cacheTimeout
			private	const SynchronizedFileMap	fileCache
	@Inject	private const BedSheetServer		bedServer

	new make(Uri:File dirMappings, IocEnv env, ActorPools actorPools, |This|? in) {
		this.cacheTimeout = env.isProd ? 2min : 2sec
		
		in?.call(this)
		
		this.fileCache = SynchronizedFileMap(actorPools["afBedSheet.system"], cacheTimeout) { it.valType = FileAsset# }
	}
	
	override FileAsset? getOrAddOrUpdate(File key, |File->Obj?| valFunc) {
		fileCache.getOrAddOrUpdate(key, valFunc)
	}
	
	** Removes the given 'FileAsset' from the internal cache.
	override Void remove(FileAsset fileAsset) {
		fileCache.remove(fileAsset.file)
	}
	
	** Clears the internal 'FileAsset' cache.
	override Void clear() {
		fileCache.clear
	}
	
	override Uri toClientUrl(Uri localUrl, File file) {
		// file is used by Cold Feet so it can generate a digest 
		bedServer.toClientUrl(localUrl)		
	}
}
