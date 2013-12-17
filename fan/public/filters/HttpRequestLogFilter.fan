using afIoc::Inject
using afIoc::RegistryShutdownHub
using webmod::LogMod
using afIocConfig::IocConfigSource

** Logs HTTP requests to file in the [W3C Extended Log File Format]`http://www.w3.org/TR/WD-logfile.html`. 
** Uses [LogMod]`webmod::LogMod`. 
** 
** To enable, contribute the filter to the HttpPipeline and set the log dir:
** 
** pre>
**   @Contribute { serviceType=HttpPipeline# }
**   static Void contributeHttpPipeline(OrderedConfig conf) {
**     conf.addOrdered("HttpRequestLogFilter", conf.autobuild(HttpRequestLogFilter#), ["after: BedSheetFilters"])
**   }
** 
**   @Contribute { serviceType=ApplicationDefaults# } 
**   static Void contributeApplicationDefaults(MappedConfig conf) {
**     conf[ConfigIds.httpRequestLogDir]             = `/my/log/dir/`
**     conf[ConfigIds.httpRequestLogFilenamePattern] = "afBedSheet-{YYYY-MM}.log"
**   }
** <pre
** 
** See `util::FileLogger` to configure datetime patterns for your log files.
** 
** The 'fields' property configures the format of the log records. It is a string of field names 
** separated by a space. The following field names are supported:
** 
**   - **date**: UTC date as DD-MM-YYYY
**   - **time**: UTC time as hh:mm:ss
**   - **c-ip**: the numeric IP address of the remote client socket
**   - **c-port**: the IP port of the remote client socket
**   - **cs-method**: the request method such as GET
**   - **cs-uri**: the encoded request uri (path and query)
**   - **cs-uri-stem**: the encoded path of the request uri
**   - **cs-uri-query**: the encoded query of the request uri
**   - **sc-status**: the return status code
**   - **time-taken**: the time taken to process request in milliseconds
**   - **cs(HeaderName)**: request header value such 'User-Agent'
** 
** If any unknown fields are specified or not available then "-" is logged. Example log record:
** 
**   2013-02-22 13:13:13 127.0.0.1 - GET /doc - 200 222 "Mozilla/5.0 (Windows; U; Windows NT 6.1; en-US) etc" "http://localhost/index"
** 
const mixin HttpRequestLogFilter : HttpPipelineFilter {

	** Directory where the request log files are written.
	** 
	** @see `ConfigIds.httpRequestLogDir`
	abstract File dir()

	** Log filename pattern. 
	** 
	** @see `ConfigIds.httpRequestLogFilenamePattern`
	abstract Str filenamePattern()

	** Format of the web log records as a string of names.
	** 
	** @see `ConfigIds.httpRequestLogFields`
	abstract Str fields()
}

internal const class HttpRequestLogFilterImpl : HttpRequestLogFilter {
	
	override const File dir

	@Inject @Config { id="afBedSheet.httpRequestLog.filenamePattern" } 
	override const Str filenamePattern

	@Inject @Config { id="afBedSheet.httpRequestLog.fields" } 
	override const Str fields

	private const LogMod logMod
	
	internal new make(RegistryShutdownHub shutdownHub, IocConfigSource configSource, |This|in) { 
		in(this)

		dir 	= configSource.get("afBedSheet.httpRequestLog.dir") ?: throw BedSheetErr(BsErrMsgs.requestLogFilterDirCannotBeNull)
		logMod  = LogMod { it.dir=this.dir; it.filename=this.filenamePattern; it.fields=this.fields }
		logMod.onStart

		shutdownHub.addRegistryShutdownListener("RequestLogFilter", [,], |->| { logMod.onStop })
	}
	
	override Bool service(HttpPipeline handler) {
		logMod.onService
		return handler.service		
	}
}
