using afIoc::Inject

** Cross Origin Resource Sharing (CORS) is a strategy for browsers to overcome the limitations of 
** cross domain scripting. The handshake is done via http headers:
** 
**  1. The browser sets CORS specific http headers in the request
**  2. The server inspects the headers and sets its own http headers in the response
**  3. The browser asserts the resonse headers
** 
** On the browser side, most of the header setting and checking is done automatically by 
** 'XMLHttpRequest'. On the server side, contribute the following routes to the paths that will 
** service the ajax requests:
** 
** pre>
** @Contribute { serviceType=Routes# }
** static Void contributeRoutes(OrderedConfig conf) {
** 
**   simpleRoute    := Route(`<simple-path>`,    CorsHandler#serviceSimple,    "GET POST")
**   preflightRoute := Route(`<preflight-path>`, CorsHandler#servicePrefilght, "OPTIONS")
** 
**   conf.add("corsSimple",    simpleRoute,    ["before: routes"])
**   conf.add("corsPreflight", preflightRoute, ["before: routes"])
** 
** }
** <pre
** 
** And set the following config values:
** - `ConfigIds.corsAllowedOrigins`
** - `ConfigIds.corsAllowCredentials`
** - `ConfigIds.corsExposeHeaders`
** - `ConfigIds.corsAllowedMethods`
** - `ConfigIds.corsAllowedHeaders`
** - `ConfigIds.corsMaxAge`
** 
** @see the following for specifics:
**  - `http://www.w3.org/TR/cors/`
**  - `http://www.html5rocks.com/en/tutorials/cors/`
**  - `https://developer.mozilla.org/en-US/docs/HTTP/Access_control_CORS`
**  - `http://api.brain-map.org/examples/doc/scatter/javascripts/jquery.ie.cors.js.html`
const mixin CorsHandler {
	
	** Sets response headers if the request a simple CORS request. 
	** Returns 'false'.
	** Uri not used.
	abstract Bool serviceSimple(Uri uri := ``)

	** Map to an 'OPTIONS' http method to service complex CORS preflight reqs.
	** Returns 'true' because the real request should follow with a different http method.
	** Uri not used.
	abstract Bool servicePrefilght(Uri uri := ``)
}

internal const class CorsHandlerImpl : CorsHandler {
	private const static Log log := Utils.getLog(CorsHandler#)

	@Inject
	private const HttpRequest	req

	@Inject
	private const HttpResponse	res
	
	@Inject @Config{ id="afBedSheet.cors.allowedOrigins" }
	private const Str? corsAllowedOrigins

	@Inject @Config{ id="afBedSheet.cors.allowCredentials" }
	private const Bool corsAllowCredentials

	@Inject @Config{ id="afBedSheet.cors.exposeHeaders" }
	private const Str? corsExposeHeaders

	@Inject @Config{ id="afBedSheet.cors.allowedMethods" }
	private const Str corsAllowedMethods

	@Inject @Config{ id="afBedSheet.cors.allowedHeaders" }
	private const Str? corsAllowedHeaders

	@Inject @Config{ id="afBedSheet.cors.maxAge" }
	private const Duration? corsMaxAge

	private const Regex[] domainGlobs

	internal new make(|This|in) { 
		in(this) 
		domainGlobs = (corsAllowedOrigins ?: "").split(',').map { Regex.glob(it) }
	}
	
	override Bool serviceSimple(Uri uri := ``) {
		if (!isSimpleReq)
			return false
		
		origin := req.headers.origin
		log.debug("CORS Simple request from origin '$origin'")
		
		if (!domainGlobs.any |domain| { domain.matches(origin) }) {
			log.warn(BsMsgs.corsOriginDoesNotMatchAllowedDomains(origin, corsAllowedOrigins))
			return false
		}
		res.headers["Access-Control-Allow-Origin"]	 = origin

		if (corsAllowCredentials)
			res.headers["Access-Control-Allow-Credentials"]	 = "true"

		if (corsExposeHeaders != null)
			res.headers["Access-Control-Expose-Headers"]	 = corsExposeHeaders

		return false
	}

	override Bool servicePrefilght(Uri uri := ``) {
		if (!isPreflightReq)
			return false

		origin := req.headers.origin
		requestedMethod := req.headers.accessControlRequestMethod
		log.debug("CORS Preflight request from origin '$origin'")
		
		if (!domainGlobs.any |domain| { domain.matches(origin) }) {
			log.warn(BsMsgs.corsOriginDoesNotMatchAllowedDomains(origin, corsAllowedOrigins))
			return false
		}
		res.headers["Access-Control-Allow-Origin"]	 = origin.toStr

		if (!corsAllowedMethods.upper.split(',').contains(requestedMethod))
			log.warn(BsMsgs.corsOriginDoesNotMatchAllowedMethods(requestedMethod, corsAllowedMethods))
		res.headers["Access-Control-Allow-Methods"]	 = corsAllowedMethods
		
		if (corsAllowCredentials)
			res.headers["Access-Control-Allow-Credentials"]	 = "true"

		if (req.headers.accessControlRequestHeaders != null) {
			reqHeaders := req.headers.accessControlRequestHeaders
			if (corsAllowedHeaders == null || !corsAllowedHeaders.split(',').containsAll(reqHeaders.split(',')))
				log.warn(BsMsgs.corsRequestHeadersDoesNotMatchAllowedHeaders(reqHeaders, corsAllowedHeaders))
			res.headers["Access-Control-Allow-Headers"]	 = corsAllowedHeaders
		}
		
		if (corsMaxAge != null)
			res.headers["Access-Control-Max-Age"]	 = corsMaxAge.toSec.toStr

		// that's all for the preflight request - returning the headers should be enough 
		return true
	}

	
	** @see http://www.html5rocks.com/en/tutorials/cors/#toc-types-of-cors-requests
	private Bool isSimpleReq() {
		if (!"HEAD GET POST".split.contains(req.httpMethod))
			return false
		
		if (req.headers.origin == null)
			return false
		
		return true
	}

	** @see http://www.html5rocks.com/en/tutorials/cors/#toc-types-of-cors-requests
	private Bool isPreflightReq() {
		if ("OPTIONS" != req.httpMethod)
			return false

		if (req.headers.origin == null)
			return false

		if (req.headers.accessControlRequestMethod == null)
			return false

		return true
	}
}
