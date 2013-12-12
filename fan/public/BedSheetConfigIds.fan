
// FIXME: rename to BedSheetConfigIds
** Config values as provided by BedSheet. To change their value, override them in your 'AppModule'. 
** Example:
** 
** pre>
** @Contribute { serviceType=ApplicationDefaults# } 
** static Void configureApplicationDefaults(MappedConfig conf) {
**   conf[ConfigIds.gzipThreshold] = 500
** }
** <pre
const mixin BedSheetConfigIds {
	
	** How often the `AppDestroyer` pings the proxy to keep the app alive.
	** Defaults to '1sec'.
	static const Str proxyPingInterval				:= "afBedSheet.appDestroyer.pingInterval"

	** If set to 'true' then *all* gzipping is disabled, regardless of other configuration. 
	** Defaults to 'false'.
	static const Str gzipDisabled					:= "afBedSheet.gzip.disabled"

	** The minimum output stream size, in bytes, before output is compressed using GZIP. Shorter 
	** streams are not compressed. The default is '376'.
	static const Str gzipThreshold					:= "afBedSheet.gzip.threshold"
	
	** The buffer size (in bytes) of the response OutStream buffer. The buffer is used to 
	** automatically set the 'Content-Length' response header. Any content larger than the buffer 
	** is streamed direct to the client.
	** Defaults to '32Kb'.
	static const Str responseBufferThreshold		:= "afBedSheet.responseBuffer.threshold"

	** The default page (instance of HttpStatusProcessor) to show when no specific page has been 
	** specified for a http status code.
	** Defaults to 'conf.autobuild(HttpStatusPageDefault#)'
	static const Str httpStatusDefaultPage			:= "afBedSheet.httpStatus.defaultPage"
	
	** The number of stack frames to print in logs and error pages.
	** Defaults to '50'
	static const Str noOfStackFrames				:= "afBedSheet.errPrinter.noOfStackFrames"
	
	** Directory where the request log files are written. Must be supplied.
	** 
	** @see `RequestLogFilter`
	static const Str httpRequestLogDir				:= "afBedSheet.httpRequestLog.dir"

	** Log filename pattern.
	** The name may contain a pattern between '{}' using the pattern format of 'DateTime.toLocale'. 
	** For example to maintain a log file per month, use a filename such as 'mylog-{YYYY-MM}.log'.
	** 
	** Defaults to 'afBedSheet-{YYYY-MM}.log'
	** 
	** @see `RequestLogFilter`
	static const Str httpRequestLogFilenamePattern	:= "afBedSheet.httpRequestLog.filenamePattern" 

	** Format of the web log records as a string of names.
	** 
	** Defaults to 'date time c-ip cs(X-Real-IP) cs-method cs-uri-stem cs-uri-query sc-status time-taken cs(User-Agent) cs(Referer) cs(Cookie)'
	** 
	** @see `RequestLogFilter`
	static const Str httpRequestLogFields			:= "afBedSheet.httpRequestLog.fields"

	// FIXME: err page disable
	** Set to 'true' to disable the default detailed BedSheet ErrPage.
	** You should do this in production.
	** Defaults to 'false'
	static const Str errPageDisabled				:= "afBedSheet.errPage.disabled"
		
	** When printing 'SrcCodeErrs', this is the number of lines of code to print before and 
	** after the line in error. 
	** Defaults to '5'
	static const Str srcCodeErrPadding				:= "afBedSheet.plastic.srcCodeErrPadding"
}
