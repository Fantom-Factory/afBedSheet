
internal const class FileProcessor : ResponseProcessor {
	
	// simply convert the File into a FileAsset...
	override Obj process(Obj fileObj) {
		file := ((File) fileObj).normalize
		return Asset(file)
	}
}
