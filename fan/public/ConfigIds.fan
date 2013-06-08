
** A list config values provided by BedSheet. To change their value, override them in your 
** 'AppModule'. Example:
** 
** pre>
** @Contribute { serviceType=ConfigSource# } 
** static Void configureConfigSource(MappedConfig config) {
**   config.addOverride(ConfigIds.gzipThreshold, "my.gzip.threshold", 500)
** }
** <pre
const class ConfigIds {
	
	// TODO: code for other environments
//	static const Str devMode					:= "afBedsheet.devMode"
	
	** If a request uri of '/' is received it is automatically routed (internally) to this uri.  
	** Defaults to '/index', set to 'null' to disable.
	static const Str welcomePage				:= "afBedSheet.welcomePage"

	** If set to 'true' then *all* gzipping is disabled, regardless of other configuration. 
	** Defaults to 'false'.
	static const Str gzipDisabled				:= "afBedSheet.gzip.disabled"

	** The minimum output stream size, in bytes, before output is compressed using GZIP. Shorter 
	** streams are not compressed. The default is '376'.
	static const Str gzipThreshold				:= "afBedSheet.gzip.threshold"
	
	** The buffer size (in bytes) of the response OutStream buffer. The buffer is used to 
	** automatically set the 'Content-Length' response header. Any content larger than the buffer 
	** is streamed direct to the client. 
	static const Str responseBufferThreshold	:= "afBedSheet.responseBuffer.threshold"
	
}
