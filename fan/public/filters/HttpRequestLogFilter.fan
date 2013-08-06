using afIoc::Inject
using afIoc::RegistryShutdownHub
using webmod::LogMod

**
** Uses [LogMod]`webmod::LogMod` to generate a server log file for all HTTP requests in the [W3C 
** Extended Log File Format]`http://www.w3.org/TR/WD-logfile.html`. 
** 
** To enable, contribute the filter to the HttpPipeline and set the log dir:
** 
** pre>
**   @Contribute { serviceType=HttpPipeline# }
**	 static Void contributeHttpPipeline(OrderedConfig conf) {
**     conf.addOrdered("HttpRequestLogFilter", conf.autobuild(HttpRequestLogFilter#), ["after: BedSheetFilters"])
**   }
** 
**   @Contribute { serviceType=ApplicationDefaults# } 
**   static Void contributeApplicationDefaults(MappedConfig conf) {
**     conf[ConfigIds.requestLogDir] = `/my/log/dir/`.toFile
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
**   2011-02-25 03:22:45 0:0:0:0:0:0:0:1 - GET /doc - 200 247
**     "Mozilla/5.0 (Windows; U; Windows NT 6.1; en-US) AppleWebKit/534.10 (KHTML, like Gecko) Chrome/8.0.552.237 Safari/534.10"
**     "http://localhost/tag"
** 
const mixin HttpRequestLogFilter : HttpPipelineFilter {

	** Directory where the request log files are written.
	** 
	** @see `ConfigIds.requestLogDir`
	abstract File dir()

	** Log filename pattern. 
	** 
	** @see `ConfigIds.requestLogFilenamePattern`
	abstract Str filenamePattern()

	** Format of the web log records as a string of names.
	** 
	** @see `ConfigIds.requestLogFields`
	abstract Str fields()
}

internal const class HttpRequestLogFilterImpl : HttpRequestLogFilter {
	
	override const File dir

	@Inject @Config { id="afBedSheet.httpRequestLog.filenamePattern" } 
	override const Str filenamePattern

	@Inject @Config { id="afBedSheet.httpRequestLog.fields" } 
	override const Str fields

	private const LogMod logMod
	
	internal new make(RegistryShutdownHub shutdownHub, ConfigSource configSource, |This|in) { 
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
