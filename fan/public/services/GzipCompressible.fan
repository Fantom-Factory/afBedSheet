
** Holds a list of `MimeType`s that may be gzip'ed in a http response. A standard set of types are 
** configured by default, to add to the list:
** 
** pre>
** 	@Contribute { serviceType=GzipCompressible# }
**	static Void configureGzipCompressible(MappedConfig config) {
**		config.addMapped(MimeType("text/funky"), true)
**  }
** <pre
** 
const class GzipCompressible {
	
	private const Str:Bool compressibleMimeTypes
	
	internal new make(MimeType:Bool compressibleMimeTypes) {
		comTypes := Utils.makeMap(Str#, Bool#)
		compressibleMimeTypes.each |val, mime| {
			comTypes[toKey(mime)] = val
		}
		this.compressibleMimeTypes = comTypes.toImmutable
	}
	
	** Returns 'true' if the given `MimeType` may be compressed.
	** 
	** Only the 'mediaType' and 'subType' are used for matching, case is ignored.
	Bool isCompressible(MimeType? mimeType) {
		if (mimeType == null)
			return false
		return compressibleMimeTypes.get(toKey(mimeType), false)
	}
	
	private Str toKey(MimeType mime) {
		"${mime.mediaType}/${mime.subType}"
	}
}
