
@Serializable
const class ConfigIds {
	
	static const Str devMode		:= "afBedsheet.devMode"
	
	** Minimum output stream size, in bytes, before output is compressed using GZIP. Shorter 
	** streams are not compressed. The default is '100'.
	// TODO: use this! Need to make some BufferedGZipOutputStream thing
	static const Str minGzipSize	:= "afbedSheet.minGzipSize"
	
}
