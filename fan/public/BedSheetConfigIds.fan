
** [IocConfig]`http://repo.status302.com/doc/afIocConfig/#overview` values as provided by BedSheet. 
** To change their value, override them in your 'AppModule'. 
** Example:
** 
** pre>
** @Contribute { serviceType=ApplicationDefaults# } 
** static Void configureApplicationDefaults(MappedConfig conf) {
**   conf[BedSheetConfigIds.gzipThreshold] = 500
** }
** <pre
const mixin BedSheetConfigIds {
	
	** How often the 'AppDestroyer' pings the proxy to keep the app alive.
	** 
	** Defaults to '1sec'.
	static const Str proxyPingInterval				:= "afBedSheet.appDestroyer.pingInterval"

	** If set to 'true' then *all* gzipping is disabled, regardless of other configuration. 
	** 
	** Defaults to 'false'.
	static const Str gzipDisabled					:= "afBedSheet.gzip.disabled"

	** The minimum output stream size, in bytes, before output is compressed using GZIP. Shorter 
	** streams are not compressed. 
	** 
	** Defaults to '376' (bytes).
	static const Str gzipThreshold					:= "afBedSheet.gzip.threshold"
	
	** The buffer size (in bytes) of the response OutStream buffer. The buffer is used to 
	** automatically set the 'Content-Length' response header. Any content larger than the buffer 
	** is streamed direct to the client.
	** 
	** Defaults to '32 * 1024' (32Kb).
	static const Str responseBufferThreshold		:= "afBedSheet.responseBuffer.threshold"

	** The default `HttpStatusProcessor` to use when no specific processor has been defined for a given http status 
	** code.
	** 
	** Defaults to 'conf.autobuild(DefaultHttpStatusProcessor#)' which sets the http status code in the response and 
	** renders the standard BedSheet status page.
	static const Str defaultHttpStatusProcessor		:= "afBedSheet.httpStatusProcessors.default"

	** The default `ErrProcessor` to use when no specific processor has been defined for a given Err.
	** 
	** Defaults to 'conf.autobuild(DefaultErrProcessor#)' which sets the http status code in the response to 500 and 
	** renders the standard BedSheet verbose error page.
	static const Str defaultErrProcessor			:= "afBedSheet.errProcessors.default"
	
	** The number of stack frames to print in logs and error pages.
	** 
	** Defaults to '75'
	static const Str noOfStackFrames				:= "afBedSheet.errPrinter.noOfStackFrames"
	
	** When printing 'SrcCodeErrs', this is the number of lines of code to print before and 
	** after the line in error.
	**  
	** Defaults to '5'
	static const Str srcCodeErrPadding				:= "afBedSheet.plastic.srcCodeErrPadding"
	
	** Set to 'true' to ensure the welcome page is never displayed. 
	** 
	** The welcome page is displayed in place of a 404 when no routes have been defined. So this config is useful if 
	** all your routing is done via 'Middleware'.
	**  
	** Defaults to 'false'
	static const Str disableWelcomePage				:= "afBedSheet.disableWelcomePage"

	** Set host to the public facing domain. This config is not mandatory but is often required by 3rd party libraries 
	** when running in production mode, such as SiteMap and Google Analytics. Host may also be used to create absolute
	** urls.
	** 
	** Defaults to 'http://localhost:<PORT>'
	static const Str host							:= "afBedSheet.host"



	// --- LoggingMiddleware ----
	
	** Directory where request log files are to be written. 
	** Set to enable request logging. 
	** Must end in a trailing /slash/.
	** 
	** @see `RequestLogFilter`
	static const Str requestLogDir					:= "afBedSheet.requestLog.dir"

	** Log filename pattern.
	** The name may contain a pattern between '{}' using the pattern format of 'DateTime.toLocale'. 
	** For example to maintain a log file per month, use a filename such as 'mylog-{YYYY-MM}.log'.
	** 
	** Defaults to 'afBedSheet-{YYYY-MM}.log'
	** 
	** @see `RequestLogFilter`
	static const Str requestLogFilenamePattern		:= "afBedSheet.requestLog.filenamePattern" 

	** Format of the web log records as a string of names.
	** 
	** Defaults to 'date time c-ip cs(X-Real-IP) cs-method cs-uri-stem cs-uri-query sc-status time-taken cs(User-Agent) cs(Referer) cs(Cookie)'
	** 
	** @see `RequestLogFilter`
	static const Str requestLogFields				:= "afBedSheet.requestLog.fields"

}
