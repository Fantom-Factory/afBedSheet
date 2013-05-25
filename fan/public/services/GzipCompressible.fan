
const class GzipCompressible {
	
	private const MimeType[] compressibleMimeTypes
	
	new make(MimeType[] compressibleMimeTypes) {
		this.compressibleMimeTypes = compressibleMimeTypes.toImmutable
	}
	
	Bool isCompressible(MimeType? mimeType) {
		if (mimeType == null)
			return false
		return compressibleMimeTypes.any { 
			mimeType.mediaType == it.mediaType && mimeType.subType == it.subType 
		}
	}
}
