using concurrent

** (Response Object) - 
** An asset, such as 'File', which may be sent to the client.  
** 
** An 'Asset' instance wraps up all the information needed to send it to a client. 
** The corresponding Asset *ResponseProcessor* sets the following HTTP headers: 
** 
**  - 'Cache-Control'
**  - 'Content-Length'
**  - 'Content-Type'
**  - 'ETag'
**  - 'Last-Modified'
** 
** Should the request headers allow, it may also respond with a '304 - Modified' response.
** The Asset *ResponseProcessor* also correctly responds to HEAD requests.
** 
** When serving up your own files and images (say, from a database), it is recommended that your *Route Handler*
** return a custom 'Asset' instance, from your own 'Asset' subclass. 
** 
** You may also wish to consider returning a `ClientAsset`.  
abstract const class Asset {
	private const AtomicRef	_etagRef		:= AtomicRef()
	
	** Returns 'true' if the asset exists. (Or did at the time this class was created.)
	abstract Bool		exists()

	** Get the modified time of the asset. Note that pod files have last modified info too!
	** 
	** Returns 'null' if asset doesn't exist
	abstract DateTime?	modified()
	
	** The ETag uniquely identifies the asset and its version. 
	** The default implementation is a hash of the modified time and the asset size.
	**  
	** Returns 'null' if asset doesn't exist
	virtual Str?		etag() {
		if (_etagRef.val == null)
			_etagRef.val = exists ? "${this.size?.toHex}-${this.modified?.ticks?.toHex}" : null
		return _etagRef.val
	}

	** The size of the asset in bytes.
	** 
	** Returns 'null' if asset doesn't exist
	abstract Int?		size()
	
	** Creates an 'InStream' to read the contents of the asset.
	** A new stream should be created each time 'in()' is called.
	**  
	** Returns 'null' if asset doesn't exist, or can't be opened.
	** (Example, if the asset is a file resource).
	abstract InStream?	in()

	** Returns the content type for the asset.
	**  
	** Returns 'null' if asset doesn't exist.
	abstract MimeType?	contentType()
	
	** Creates a 'Asset' for the given file. 
	** 
	** To create a 'ClientAsset' use the 'FileHandler' or 'PodHandler' service:
	** 
	**   fileHandler.fromServerFile(file) 
	static new makeFromFile(File file) {
		FileAsset(file, null)
	}

	@NoDoc
	override Int hash() {
		etag?.hash ?: 0
	}
	
	@NoDoc
	override Bool equals(Obj? obj) {
		etag == (obj as Asset)?.etag
	}
	
	@NoDoc
	override Str toStr() {
		etag ?: "null"
	}
}
