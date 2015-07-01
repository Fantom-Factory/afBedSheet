
** [IocConfig]`pod:afIocConfig` values as provided by BedSheet. 
** To change their value, override them in your 'AppModule'. 
** Example:
** 
** pre>
** syntax: fantom 
** @Contribute { serviceType=ApplicationDefaults# } 
** static Void configureApplicationDefaults(Configuration conf) {
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

	** The default response to process when no specific response has been defined for a given HTTP 
	** status code.
	** 
	** Defaults to a method call to an internal handler which sets the HTTP status code and renders 
	** the standard BedSheet status page.
	static const Str defaultHttpStatusResponse		:= "afBedSheet.defaultHttpStatusResponse"

	** The default response to process when no specific response has been defined for a given Err.
	** 
	** Defaults to a method call to an internal handler which sets the HTTP status code and renders 
	** the standard verbose BedSheet error page.
	static const Str defaultErrResponse				:= "afBedSheet.defaultErrResponse"
	
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

	** The public facing domain; used by `BedSheetServer` to create absolute URLs. 
	** 3rd party libraries, such as SiteMap and Google Analytics, require this when running in production mode. 
	** 
	** Defaults to 'http://localhost:<PORT>'
	static const Str host							:= "afBedSheet.host"



	// --- Handlers ----

	** The local URL under which pod resources are served.
	** The URL must start and end with a slash.
	** 
	** Defaults to '`/pods/`' 
	static const Str podHandlerBaseUrl				:= "afBedSheet.podHandler.baseUrl"
	
	** The default 'Cache-Control' HTTP response header to set when serving static files. 
	** Example, to cache files for 1 day:
	** 
	**   "max-age=${1day.toSec}"
	** 
	** Ideally you should use an asset caching strategy, such as [Cold Feet]`http://www.fantomfactory.org/pods/afColdFeet`, 
	** which sets this for you. 
	** 
	** Defaults to 'null'
	static const Str fileAssetCacheControl			:= "afBedSheet.fileAsset.cacheControl"



	// --- LoggingMiddleware ----
	
	** Directory where request log files are to be written. 
	** Set to enable request logging. 
	** Must end in a trailing /slash/.
	** 
	** @see `RequestLogMiddleware`
	@NoDoc @Deprecated { msg="Use 'RequestLogger' instead" }
	static const Str requestLogDir					:= "afBedSheet.requestLog.dir"

	** Log filename pattern.
	** The name may contain a pattern between '{}' using the pattern format of 'DateTime.toLocale'. 
	** For example to maintain a log file per month, use a filename such as 'mylog-{YYYY-MM}.log'.
	** 
	** Defaults to 'afBedSheet-{YYYY-MM}.log'
	** 
	** @see `RequestLogMiddleware`
	@NoDoc @Deprecated { msg="Use 'RequestLogger' instead" }
	static const Str requestLogFilenamePattern		:= "afBedSheet.requestLog.filenamePattern" 

	** Format of the web log records as a string of names.
	** 
	** Defaults to 'date time c-ip cs(X-Real-IP) cs-method cs-uri-stem cs-uri-query sc-status time-taken cs(User-Agent) cs(Referer) cs(Cookie)'
	** 
	** @see `RequestLogMiddleware`
	@NoDoc @Deprecated { msg="Use 'RequestLogger' instead" }
	static const Str requestLogFields				:= "afBedSheet.requestLog.fields"

}
