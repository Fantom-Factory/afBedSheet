
** (Service) - 
** Holds a list of 'MimeTypes' that may be gzip'ed in a HTTP response. 
** A standard set of types are configured by default. To add to the list:
** 
** pre>
** syntax: fantom
** @Contribute { serviceType=GzipCompressible# }
** Void configureGzipCompressible(Configuration config) {
**     config[MimeType("text/funky")] = true
** }
** <pre
**
** Because IoC kindly coerces the contribution types for us, the above could be re-written as: 
** 
** pre>
** syntax: fantom
** @Contribute { serviceType=GzipCompressible# }
** Void configureGzipCompressible(Configuration config) {
**     config["text/funky"] = true
** }
** <pre
** 
** @uses a Configuration of 'MimeType:Bool'
@NoDoc	// Don't overwhelm the masses!
const mixin GzipCompressible {
	
	** Returns 'true' if the given [MimeType]`sys::MimeType` may be compressed.
	** 
	** Only the 'mediaType' and 'subType' are used for matching, case is ignored.
	abstract Bool isCompressible(MimeType? mimeType)
}

internal const class GzipCompressibleImpl : GzipCompressible {  

	private const Str:Bool compressibleMimeTypes
	
	internal new make(MimeType:Bool compressibleMimeTypes) {
		comTypes := Utils.makeMap(Str#, Bool#)
		compressibleMimeTypes.each |val, mime| {
			comTypes[toKey(mime)] = val
		}
		this.compressibleMimeTypes = comTypes.toImmutable
	}
	
	override Bool isCompressible(MimeType? mimeType) {
		if (mimeType == null)
			return false
		return compressibleMimeTypes.get(toKey(mimeType), false)
	}
	
	private Str toKey(MimeType mime) {
		"${mime.mediaType}/${mime.subType}"
	}
}
