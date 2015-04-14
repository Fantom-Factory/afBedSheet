using afIoc
using concurrent

// TODO: make FileAsset internal and remove @Deprecated
@NoDoc @Deprecated { msg="Use StaticAsset or CachableAsset instead" }
const class FileAsset : CachableAsset {

			 const 	File			file
	override const 	Bool			exists
	override const 	DateTime?		modified
	override const 	Int?			size
	override const 	MimeType?		contentType
	override const 	Uri?			localUrl

	@NoDoc
	new makeStatic(File file, AssetCache? assetCache) : super.make(assetCache) {
		this.file 		= file
		this.exists		= file.exists
		this.modified	= file.modified?.floor(1sec)
		this.size		= file.size
		this.contentType= exists ? file.mimeType : null
	}

	@NoDoc @Deprecated { msg="Use StaticAsset.makeFromFile() instead" }
	new makeLegacy(File file, Uri? localUrl, Uri? clientUrl) : this.makeStatic(file, null) {
		this.localUrl	= localUrl
	}

	@NoDoc @Inject
	new makeCachable(Uri localUrl, File file, AssetCache assetCache) : this.makeStatic(file, assetCache) {
		this.localUrl		= localUrl
	}

	override InStream? in() {
		if (file.isDir)	// not allowed, until I implement it! 
			throw HttpStatusErr(403, BsErrMsgs.directoryListingNotAllowed(localUrl))
		return file.exists ? file.in : null
	}
	override DateTime? modifiedNotCached() {
		file.modified
	}
}

