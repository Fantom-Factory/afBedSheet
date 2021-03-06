
** [IocConfig]`pod:afIocConfig` values as provided by BedSheet. 
** To change their value, override them in your 'AppModule'. 
** Example:
** 
** pre>
** syntax: fantom 
** @Contribute { serviceType=ApplicationDefaults# } 
** Void configureApplicationDefaults(Configuration conf) {
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

	@NoDoc @Deprecated { msg="BedSheet now honours 'errTraceMaxDepth' from etc/sys/config.props" }
	static const Str noOfStackFrames				:= "afBedSheet.errPrinter.noOfStackFrames"
	
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

	** Routes handling is case-insensitive and ignores directory URLs.
	** If a Route is matched, but the URL is different to the prescribed URL this strategy defines what should happen next.   
	** 
	** Valid options are:
	**  - 'ignore' - do nothing and process the Route
	**  - 'redirect' - redirect to the prescribed canonical URL
	** 
	** Defaults to 'redirect'
	static const Str canonicalRouteStrategy			:= "afBedSheet.canonicalRouteStrategy"



	// --- Handlers ----

	** The local URL under which pod resources are served.
	** The URL must start and end with a slash.
	** 
	** Defaults to '`/pod/`' because Fantom '.js.map' files are hardcoded to be served under '/pod/'.
	static const Str podHandlerBaseUrl				:= "afBedSheet.podHandler.baseUrl"

	** The local URL under which Fantom source code is served.
	** The URL must start and end with a slash.
	** 
	** Defaults to '`/dev/`' because Fantom '.js.map' files are hardcoded to be served under '/dev/'.
	** 
	** Note that source maps are only enabled in 'dev' environments. To enable in other environments 
	** you must manually contribute your own value of '`/dev/`'.
	**  
	** See 'compilerJs::SourceMap.write()' and [JS Source Maps on Fantom Forum]`http://fantom.org/forum/topic/2531`.
	static const Str srcMapHandlerBaseUrl			:= "afBedSheet.srcMapHandler.baseUrl"
	
	** The default 'Cache-Control' HTTP response header to set when serving static files. 
	** Example, to cache files for 1 day:
	** 
	**   "max-age=${1day.toSec}"
	** 
	** Ideally you should use an asset caching strategy, such as [Cold Feet]`http://eggbox.fantomfactory.org/pods/afColdFeet`, 
	** which sets this for you. 
	** 
	** Defaults to 'null'
	static const Str fileAssetCacheControl			:= "afBedSheet.fileAsset.cacheControl"

}
