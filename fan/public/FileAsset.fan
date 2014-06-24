
** A wrapper around a 'File' object used to prevent excessive polling of the file system.
** As every call to 'File.exists()' typically takes [at least 8ms-12ms]`http://stackoverflow.com/questions/6321180/how-expensive-is-file-exists-in-java#answer-6321277`, 
** this is probably a good thing!
** 
** 'FileAssets' are acquired from 'FileHander' and should be used to embed client URLs in your web pages.
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
	** This *may* be the same as 'clientUrl' or it may not. 
	** If in doubt, use the 'clientUrl' instead.
	**  
	** Returns 'null' if file doesn't exist
	const Uri?		localUrl

	** The URL that clients should use to access the file resource. 
	** The 'clientUrl' contains any extra 'WebMod' path segments required to reach the 'BedSheet WebMod'.
	** It also contains path segments as provided by any asset caching strategies, such as [Cold Feet]`http://www.fantomfactory.org/pods/afColdFeet`.
	** 
	** Client URLs are designed to be used / embedded in your HTML. 
	**   
	** Returns 'null' if file doesn't exist
	const Uri?		clientUrl
	
	internal new make(|This|in) { in(this) }
}
