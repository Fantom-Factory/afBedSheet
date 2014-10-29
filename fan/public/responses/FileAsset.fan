
** (Response Object) Use in place of a 'File' object to prevent excessive polling of the file system.
** As every call to 'File.exists()' typically takes [at least 8ms-12ms]`http://stackoverflow.com/questions/6321180/how-expensive-is-file-exists-in-java#answer-6321277`, 
** this is probably a good thing!
** 
** Generally you would acquire 'FileAssets' from the 'FileHander' and 'PodHander' services and use 
** them to embed client URLs in your web pages.
** 
**   fileHandler.fromLocalUrl(`/images/fanny.jpg`).clientUrl
** 
const class FileAsset {

	** The file in question
	const File		file
	
	** Returns 'true' if the file exists. (Or did at the time this class was created.)
	const Bool		exists
	
	** Get the modified time of the file, floored to 1 second which is the most precision that HTTP 
	** can deal with.
	** 
	** Returns 'null' if file doesn't exist
	const DateTime?	modified
	
	** The ETag uniquely identifies the file and its version. 
	** The default implementation is a hash of the modified time and the file size.
	**  
	** Returns 'null' if file doesn't exist
	const Str?		etag

	** The size of the file in bytes.
	** 
	** Returns 'null' if file doesn't exist
	const Int?		size
	
	** The URL relative to the 'BedSheet' [WebMod]`web::WebMod` that corresponds to the file resource. 
	** If your application is the ROOT WebMod then this will be the same as 'clientUrl'; bar any asset caching. 
	** If in doubt, use the 'clientUrl' instead.
	**  
	** Returns 'null' if file doesn't exist.
	const Uri?		localUrl

	** The URL that clients (e.g. web browsers) should use to access the file resource. 
	** The 'clientUrl' contains any extra 'WebMod' path segments required to reach the 'BedSheet WebMod'.
	** It also contains path segments as provided by any asset caching strategies, such as [Cold Feet]`http://www.fantomfactory.org/pods/afColdFeet`.
	** 
	** Client URLs are designed to be used / embedded in your HTML. 
	** 
	** Note: use `BedSheetServer` should you want an absolute URL that starts with 'http://'. 
	**   
	** Returns 'null' if file doesn't exist.
	const Uri?		clientUrl
	
	** Creates a 'FileAsset' for the given file. 
	** 'localUrl' and 'clientUrl' may be 'null' if this instance is to be passed straight to 'FileResponseProcessor'.  
	@NoDoc
	new make(File file, Uri? localUrl := null, Uri? clientUrl := null, |This|? in := null) {
		this.file 		= file
		this.exists		= file.exists
		this.modified	= file.modified?.floor(1sec)
		this.size		= file.size
		this.etag		= this.exists ? "${this.size?.toHex}-${this.modified?.ticks?.toHex}" : null
		this.localUrl	= localUrl
		this.clientUrl	= clientUrl
		in?.call(this)
	}
	
	@NoDoc
	override Int hash() {
		file.hash
	}
	
	@NoDoc
	override Bool equals(Obj? obj) {
		file == (obj as FileAsset)?.file
	}
	
	** Returns 'clientUrl' so this can be printed in HTML, or 'file.toStr' if 'clientUrl' is 'null'.
	override Str toStr() {
		clientUrl?.toStr ?: file.toStr
	}
}
