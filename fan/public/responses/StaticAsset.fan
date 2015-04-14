using concurrent

** (Response Object) An asset, such as a 'File', which may be stored on the file system or in a database. 
** 
** Generally 'StaticAssets' are acquired from the 'FileHander' and 'PodHander' services and used to embed client URLs in your web pages.
** 
**   url := fileHandler.fromLocalUrl(`/images/fanny.jpg`).clientUrl.encode
** 
** Alternatively you may create your own 'StaticAsset' objects for returning files from a database.
** 
abstract const class StaticAsset {
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
	** Returns 'null' if asset doesn't exist.
	abstract InStream?	in()

	** Returns the content type for the asset.
	**  
	** Returns 'null' if asset doesn't exist.
	abstract MimeType?	contentType()
	
	** Creates a 'StaticAsset' for the given file. Note this asset is not a 'ClientAsset'.
	static new makeFromFile(File file) {
		FileAsset(file, null)
	}

	@NoDoc
	override Int hash() {
		etag.hash
	}
	
	@NoDoc
	override Bool equals(Obj? obj) {
		etag == (obj as StaticAsset)?.etag
	}
	
	@NoDoc
	override Str toStr() {
		etag ?: "null"
	}
}
