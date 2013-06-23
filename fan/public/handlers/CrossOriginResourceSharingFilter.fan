using afIoc::Inject

**
** 
** @see http://www.w3.org/TR/cors/
** 
** @see http://www.html5rocks.com/en/tutorials/cors/
** 
** @see https://developer.mozilla.org/en-US/docs/HTTP/Access_control_CORS
const class CrossOriginResourceSharingFilter {
	private const static Log log := Utils.getLog(CrossOriginResourceSharingFilter#)

	@Inject
	private const Request	req

	@Inject
	private const Response	res
	
	@Inject @Config{ id="afBedSheet.cors.allowedOrigins" }
	private const Str corsAllowedOrigins

	@Inject @Config{ id="afBedSheet.cors.allowCredentials" }
	private const Bool corsAllowCredentials

	@Inject @Config{ id="afBedSheet.cors.exposeHeaders" }
	private const Str? corsExposeHeaders		// TODO: how to disable / supply null?

	@Inject @Config{ id="afBedSheet.cors.allowedMethods" }
	private const Str corsAllowedMethods

	@Inject @Config{ id="afBedSheet.cors.allowedHeaders" }
	private const Str? corsAllowedHeaders	// TODO: how to disable / supply null?

	@Inject @Config{ id="afBedSheet.cors.maxAge" }
	private const Duration? corsMaxAge	// TODO: how to disable / supply null?

	private const Regex[] domainGlobs
	
	new make(|This|in) { 
		in(this) 
		domainGlobs = corsAllowedOrigins.split(',').map { Regex.glob(it) }
	}
	
	** Map to...
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
		log.debug("CORS Preflight request from origin '$origin'")
		
		if (!domainGlobs.any |domain| { domain.matches(origin) }) {
			log.warn(BsMsgs.corsOriginDoesNotMatchAllowedDomains(origin, corsAllowedOrigins))
			return false
		}
		res.headers["Access-Control-Allow-Origin"]	 = origin

		res.headers["Access-Control-Allow-Methods"]	 = corsAllowedMethods
		
		if (corsAllowCredentials)
			res.headers["Access-Control-Allow-Credentials"]	 = "true"

		if (req.headers.containsKey("Access-Control-Request-Headers")) {
			reqHeaders := req.headers["Access-Control-Request-Headers"]
			if (corsAllowedHeaders.split(',').containsAll(reqHeaders.split(',')))
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
