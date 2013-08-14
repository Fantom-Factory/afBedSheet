using afIoc::ConcurrentCache
using afIoc::Inject

internal const class FileCache {
	private const ConcurrentCache 	cache	:= ConcurrentCache()
	private const Duration 			timeout

	new make(Duration timeout) { 
		this.timeout = timeout
	}
	
	@Operator
	Obj? get(File file) {
		((FileCacheState?) cache[file])?.payload
	}

	@Operator
	Void set(File file, Obj? val) {
		cache[file] = FileCacheState(file.modified, val)
	}
	
	Bool containsFile(File file) {
		cache.containsKey(file)
	}
	
	Obj? getOrAddOrUpdate(File file, |File->Obj| bob) {
		state := (FileCacheState?) cache[file]

		if (state?.isTimedOut(timeout) ?: true) {
			lastModified	:= state?.lastModified
			payload			:= state?.payload
			
			if (state?.isModified(file) ?: true) {
				lastModified 	= file.modified
				payload 		= bob(file)
			}
			
			state = FileCacheState(lastModified, payload)
			cache[file]	= state
		}

		return state?.payload
	}
}

internal const class FileCacheState {
	const DateTime	lastChecked
	const DateTime	lastModified	// pod files have last modified info
	const Obj?		payload
	
	new make(DateTime lastModified, Obj? payload) {
		this.lastChecked	= DateTime.now
		this.lastModified	= lastModified
		this.payload 		= payload
	}	
	
	Bool isTimedOut(Duration timeout) {
		(DateTime.now - lastChecked) > timeout
	}
	
	Bool isModified(File file) {
		file.modified > lastModified
	}
}
