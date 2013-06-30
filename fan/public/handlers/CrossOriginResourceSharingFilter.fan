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
**  simpleRoute    := ArgRoute(`<simple-path>`,    CrossOriginResourceSharingFilter#serviceSimple,    "GET POST")
**  preflightRoute := ArgRoute(`<preflight-path>`, CrossOriginResourceSharingFilter#servicePrefilght, "OPTIONS")
** 
**  config.addOrdered("corsSimple", 	simpleRoute,    ["before: routes"])
**  config.addOrdered("corsPreflight", 	preflightRoute, ["before: routes"])
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
** @see Read the following for specifics:
**  - `http://www.w3.org/TR/cors/`
**  - `http://www.html5rocks.com/en/tutorials/cors/`
**  - `https://developer.mozilla.org/en-US/docs/HTTP/Access_control_CORS`
**  - `http://api.brain-map.org/examples/doc/scatter/javascripts/jquery.ie.cors.js.html`
const class CrossOriginResourceSharingFilter {
	private const static Log log := Utils.getLog(CrossOriginResourceSharingFilter#)

	@Inject
	private const Request	req

	@Inject
	private const Response	res
	
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

	new make(|This|in) { 
		in(this) 
		domainGlobs = (corsAllowedOrigins ?: "").split(',').map { Regex.glob(it) }
	}
	
	** Map to... 
	** TODO: more docs
	public Bool serviceSimple(Uri uri) {
		if (!isSimpleReq)
			return false
		
		origin := req.headers["Origin"]
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

	** Map to an 'OPTIONS' http method
	public Bool servicePrefilght(Uri uri) {
		if (!isPreflightReq)
			return false

		origin := req.headers["Origin"]
		requestedMethod := req.headers["Access-Control-Request-Method"].upper
		log.debug("CORS Preflight request from origin '$origin'")
		
		if (!domainGlobs.any |domain| { domain.matches(origin) }) {
			log.warn(BsMsgs.corsOriginDoesNotMatchAllowedDomains(origin, corsAllowedOrigins))
			return false
		}
		res.headers["Access-Control-Allow-Origin"]	 = origin

		if (!corsAllowedMethods.upper.split(',').contains(requestedMethod))
			log.warn(BsMsgs.corsOriginDoesNotMatchAllowedMethods(requestedMethod, corsAllowedMethods))
		res.headers["Access-Control-Allow-Methods"]	 = corsAllowedMethods
		
		if (corsAllowCredentials)
			res.headers["Access-Control-Allow-Credentials"]	 = "true"

		if (req.headers.containsKey("Access-Control-Request-Headers")) {
			reqHeaders := req.headers["Access-Control-Request-Headers"]
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
		
		if (!req.headers.containsKey("Origin"))
			return false
		
		return true
	}

	** @see http://www.html5rocks.com/en/tutorials/cors/#toc-types-of-cors-requests
	private Bool isPreflightReq() {
		if ("OPTIONS" != req.httpMethod)
			return false

		if (!req.headers.containsKey("Origin"))
			return false

		if (!req.headers.containsKey("Access-Control-Request-Method"))
			return false

		return true
	}
}
