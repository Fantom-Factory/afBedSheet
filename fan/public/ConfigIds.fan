
** Config values as provided by BedSheet. To change their value, override them in your 'AppModule'. 
** Example:
** 
** pre>
** @Contribute { serviceType=ApplicationDefaults# } 
** static Void configureApplicationDefaults(MappedConfig conf) {
**   conf[ConfigIds.gzipThreshold] = 500
** }
** <pre
const class ConfigIds {
	
	** How often the `AppDestroyer` pings the proxy to keep the app alive.
	** Defaults to '1sec'.
	static const Str proxyPingInterval			:= "afBedSheet.appDestroyer.pingInterval"

	** If set to 'true' then *all* gzipping is disabled, regardless of other configuration. 
	** Defaults to 'false'.
	static const Str gzipDisabled				:= "afBedSheet.gzip.disabled"

	** The minimum output stream size, in bytes, before output is compressed using GZIP. Shorter 
	** streams are not compressed. The default is '376'.
	static const Str gzipThreshold				:= "afBedSheet.gzip.threshold"
	
	** The buffer size (in bytes) of the response OutStream buffer. The buffer is used to 
	** automatically set the 'Content-Length' response header. Any content larger than the buffer 
	** is streamed direct to the client.
	** Defaults to '32Kb'.
	static const Str responseBufferThreshold	:= "afBedSheet.responseBuffer.threshold"

	** The default page (instance of HttpStatusProcessor) to show when no specific page has been 
	** specified for a http status code.
	** Defaults to 'conf.autobuild(HttpStatusPageDefault#)'
	static const Str httpStatusDefaultPage		:= "afBedSheet.httpStatus.defaultPage"
	
	** The number of stack frames to print in logs and error pages.
	** Defaults to '50'
	static const Str noOfStackFrames			:= "afBedSheet.errUtils.noOfStackFrames"
	
	** Directory where the request log files are written. Must be supplied.
	** 
	** @see `RequestLogFilter`
	static const Str requestLogDir				:= "afBedSheet.requestLog.dir"

	** Log filename pattern.
	** The name may contain a pattern between '{}' using the pattern format of 'DateTime.toLocale'. 
	** For example to maintain a log file per month, use a filename such as 'mylog-{YYYY-MM}.log'.
	** 
	** Defaults to 'afBedSheet-{YYYY-MM}.log'
	** 
	** @see `RequestLogFilter`
	static const Str requestLogFilenamePattern	:= "afBedSheet.requestLog.filenamePattern" 

	** Format of the web log records as a string of names.
	** 
	** Defaults to 'date time c-ip cs(X-Real-IP) cs-method cs-uri-stem cs-uri-query sc-status time-taken cs(User-Agent) cs(Referer) cs(Cookie)'
	** 
	** @see `RequestLogFilter`
	static const Str requestLogFields			:= "afBedSheet.requestLog.fields"

	** A CSV glob list of all origins (domains) allowed for Cross Origin Resource Sharing.
	** Defaults to "*" (all domains).
	** Example, "*.alienfactory.co.uk, *.heroku.com"
	**
	** @see `CrossOriginResourceSharingFilter`
	static const Str corsAllowedOrigins			:= "afBedSheet.cors.allowedOrigins"

	** If set to 'true' the 'Access-Control-Allow-Credentials' response header is set.
	** Defaults to 'false'
	** 
	** @see `CrossOriginResourceSharingFilter` 
	static const Str corsAllowCredentials		:= "afBedSheet.cors.allowCredentials"

	** A CSV list of http headers the client application is allowed access to. 
	** Defaults to 'null'.
	** 
	** @see `CrossOriginResourceSharingFilter` 
	static const Str corsExposeHeaders			:= "afBedSheet.cors.exposeHeaders"

	** A CSV list of http methods the client is allowed to make. 
	** (Only required for preflight requests.)
	** Defaults to "GET, POST".
	** 
	** @see `CrossOriginResourceSharingFilter` 
	static const Str corsAllowedMethods			:= "afBedSheet.cors.allowedMethods"
	
	** A CSV list of http heads the client is allowed to send. 
	** (Only required for preflight requests.)
	** Defaults to 'null'.
	** 
	** @see `CrossOriginResourceSharingFilter` 
	static const Str corsAllowedHeaders			:= "afBedSheet.cors.allowedHeaders"

	** The max age to tell a client to cache the preflight request for.
	** (Only required for preflight requests.)
	** Defaults to '60min', set to 'null' to disable.
	** 
	** @see `CrossOriginResourceSharingFilter` 
	static const Str corsMaxAge					:= "afBedSheet.cors.maxAge"
	
}
