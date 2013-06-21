
** Config values as provided by BedSheet. To change their value, override them in your 'AppModule'. 
** Example:
** 
** pre>
** @Contribute { serviceType=ConfigSource# } 
** static Void configureConfigSource(MappedConfig config) {
**   config.addOverride(ConfigIds.gzipThreshold, "my.gzip.threshold", 500)
** }
** <pre
const class ConfigIds {
	
	** How often the `AppDestroyer` pings the proxy to keep the app alive.
	** Defaults to '1sec'.
	static const Str pingInterval				:= "afBedSheet.appDestroyer.pingInterval"

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
