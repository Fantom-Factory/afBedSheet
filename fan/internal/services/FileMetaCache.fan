using afIoc
using afIocEnv
using afConcurrent

** Given even a call to 'File.exists()' typically takes [at least 8ms-12ms]`http://stackoverflow.com/questions/6321180/how-expensive-is-file-exists-in-java#answer-6321277`, 
** this little cache should speed things up when inspecting static files.  
** 
** Used by FileHandler, FileResponseProcessor and ColdFeet.
@NoDoc	// advanced use only
const class FileMetaCache {	
	private const SynchronizedFileMap	fileCache
	
	** The duration between individual file checks.
	const Duration cacheTimeout
	
	new make(IocEnv env, ActorPools actorPools, |This|in) {
		cacheTimeout = env.isProd ? 2min : 2sec
		in(this)
		this.fileCache = SynchronizedFileMap(actorPools["afBedSheet.system"], cacheTimeout) { it.valType = FileMeta# }
	}

	@Operator
	FileMeta get(File file) {
		fileCache.getOrAddOrUpdate(file) |File f->FileMeta| {
			FileMeta {
				it.file 	= f
				it.exists	= f.exists
				it.modified	= f.modified?.floor(1sec)
				it.size		= f.size
				it.isDir	= f.isDir
				it.etag		= it.exists ? "${it.size?.toHex}-${it.modified?.ticks?.toHex}" : null
				it.cache	= AtomicMap()
			}
		}
	}
	
	Void remove(File file) {
		fileCache.remove(file)
	}
	
	Void clear() {
		fileCache.clear
	}
}

@NoDoc	// advanced use only
const class FileMeta {

	** The file in question
	const File		file
	
	** Returns 'true' if the file exists. (Or did at the time this meta class was created.)
	const Bool		exists
	
	** Get the modified time of the file floored to 1 second which is the most precision that HTTP 
	** can deal with.
	** 
	** Returns 'null' if file doesn't exist
	const DateTime?	modified
	
	** Compute the ETag for the file being serviced which uniquely identifies the file version. 
	** The default implementation is a hash of the modified time and the file size.
	**  
	** Returns 'null' if file doesn't exist
	const Str?		etag

	** Returns 'null' if file doesn't exist
	const Int?		size
	
	** Convenience for 'file.uri.isDir'
	const Bool		isDir

	** User defined cache
	const AtomicMap	cache
	
	internal new make(|This|in) { in(this) }
}
