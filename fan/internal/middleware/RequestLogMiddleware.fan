using afIoc::Inject
using webmod::LogMod
using afIocConfig::ConfigSource
using afIocConfig::Config

** Logs HTTP requests to file in the [W3C Extended Log File Format]`http://www.w3.org/TR/WD-logfile.html`. 
** Uses [LogMod]`webmod::LogMod`. 
** 
** To enable, set the [log dir]`BedSheetConfigIds.requestLogDir` and (optionally) the 
** [filename pattern]`BedSheetConfigIds.requestLogFilenamePattern` in your 'AppModule':
** 
** pre>
**   syntax: fantom
**   @Contribute { serviceType=ApplicationDefaults# } 
**   static Void contributeAppDefaults(Configuration conf) {
**       conf[BedSheetConfigIds.requestLogDir]             = `/my/log/dir/`
**       conf[BedSheetConfigIds.requestLogFilenamePattern] = "bedSheet-{YYYY-MM}.log" // (optional)
**   }
** <pre
** 
** Note: the log dir must end in a trailing /slash/.
** 
** See `util::FileLogger` to configure datetime patterns for your log files.
** 
** The [fields]`BedSheetConfigIds.requestLogFields` property configures the format of the log records. It is a string of field names 
** separated by a space. The following field names are supported:
** 
**   syntax: table
** 
**   Field Name         Description
**   ----------------   ----------------------------------------------
**   'date'             UTC date as DD-MM-YYYY
**   'time'             UTC time as hh:mm:ss
**   'c-ip'             Numeric IP address of the remote client socket
**   'c-port'           IP port of the remote client socket
**   'cs-method'        Request method such as GET
**   'cs-uri'           Encoded request uri (path and query)
**   'cs-uri-stem'      Encoded path of the request URL
**   'cs-uri-query'     Encoded query of the request URL
**   'sc-status'        Return status code
**   'time-taken'       Time taken to process request in milliseconds
**   'cs(HeaderName)'   Request header value such 'User-Agent'
** 
** If any unknown fields are specified or not available then "-" is logged. Example log record:
** 
** pre>
** 2013-02-22 13:13:13 127.0.0.1 - GET /doc - 200 222 "Mozilla/5.0 (Windows; U; Windows NT 6.1; en-US) etc" "http://localhost/index"
** 
** <pre
@NoDoc @Deprecated { msg="Use 'RequestLogger' instead" }
const mixin RequestLogMiddleware : Middleware {

	** Directory where the request log files are written.
	** 
	** @see `BedSheetConfigIds.requestLogDir`
	abstract File? dir()

	** Log filename pattern. 
	** 
	** @see `BedSheetConfigIds.requestLogFilenamePattern`
	abstract Str filenamePattern()

	** Format of the web log records as a string of names.
	** 
	** @see `BedSheetConfigIds.requestLogFields`
	abstract Str fields()
	
	@NoDoc
	abstract Void shutdown()
}

internal const class RequestLogMiddlewareImpl : RequestLogMiddleware {
	private static const Log log	:= Utils.getLog(RequestLogMiddlewareImpl#)
	
	override const File? dir

	@Inject @Config { id="afBedSheet.requestLog.filenamePattern" } 
	override const Str filenamePattern

	@Inject @Config { id="afBedSheet.requestLog.fields" } 
	override const Str fields

	private const LogMod? logMod
	
	internal new make(ConfigSource configSource, |This|in) { 
		in(this)

		dir = configSource.get(BedSheetConfigIds.requestLogDir, File#)
		if (dir == null)
			return
		
		logMod = LogMod { it.dir=this.dir; it.filename=this.filenamePattern; it.fields=this.fields }
		logMod.onStart

		log.info(BsLogMsgs.requestLog_enabled(dir + `${filenamePattern}`))
	}
	
	override Void service(MiddlewarePipeline pipeline) {
		try	pipeline.service
		finally logMod?.onService
	}

	override Void shutdown() {
		logMod?.onStop
	}
}