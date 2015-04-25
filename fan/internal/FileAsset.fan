using afIoc
using concurrent

// TODO: make FileAsset internal and remove @Deprecated
@NoDoc @Deprecated { msg="Use Asset or ClientAsset instead" }
const class FileAsset : ClientAsset {

			 const 	File			file
	override const 	Bool			exists
	override const 	DateTime?		modified
	override const 	Int?			size
	override const 	MimeType?		contentType
	override const 	Uri?			localUrl
			const 	Uri?			legacyClientUrl

	@NoDoc	// used by Asset.makeFromFile()
	internal new makeStatic(File file, |This|? in) : super.make(in) {
		this.file 		= file
		this.exists		= file.exists
		this.modified	= file.modified?.floor(1sec)
		this.size		= file.size
		this.contentType= exists ? file.mimeType : null
	}

	@NoDoc @Deprecated { msg="Use Asset.makeFromFile() instead" }
	new makeLegacy(File file, Uri? localUrl, Uri? clientUrl) : this.makeStatic(file, null) {
		this.localUrl			= localUrl
		this.legacyClientUrl	= clientUrl
	}

	@NoDoc @Inject	// the autobuild ctor you should use
	new makeCachable(Uri localUrl, File file, |This|in) : this.makeStatic(file, in) {
		this.localUrl		= localUrl
	}
	
	override Uri? clientUrl() {
		legacyClientUrl ?: super.clientUrl
	}

	override InStream? in() {
		// Bushmasters uses the client URL as a base URL, even though it's a dir
		// Return null so it's not processed by ColdFeet
		return (!file.isDir && file.exists) ? file.in : null
	}
	
	override DateTime? actualModified() {
		file.modified
	}
}

