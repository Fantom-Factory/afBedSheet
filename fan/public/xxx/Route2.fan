
const class Route {
	** A hint at what this route matches on. Used for debugging and in 404 / 500 error pages. 
	const Str		matchHint

	** A hint at what response this route returns. Used for debugging and in 404 / 500 error pages. 
	const Str		responseHint
	
	internal const Uri		urlGlob
	internal const Str[]	httpMethods
	internal const Obj		response

	new make(Uri urlGlob, Obj response, Str httpMethod := "GET") {
		
		// FIXME check for empty path, non-abs path, //, ** not at the end, etc
		
		this.urlGlob		= urlGlob
		this.httpMethods	= httpMethod.upper.split
		this.matchHint		= httpMethod.justl(4) + " ${urlGlob}"
		this.responseHint	= response is Method ? "-> " + ((Method) response).qname : response.toStr
		this.response		= response
	}

	** Creates Routes that match default method arguments
	internal Route[]? _defRoutes() {
		method	:= (Method) response
		path	:= urlGlob.path
		numWildcards := 0
		for (i := 0; i < path.size; ++i) {
			if (path[i] == "*" || path[i] == "**")
				numWildcards++
		}
		if (numWildcards > method.params.size)
			throw ArgErr(BsErrMsgs.route_uriWillNeverMatchMethod(urlGlob, method))
		
		numMinArgs := 0
		for (i := 0; i < method.params.size; ++i) {
			if (method.params[i].hasDefault == false)
				numMinArgs++
		}
		if (numWildcards < numMinArgs)
			throw ArgErr(BsErrMsgs.route_uriWillNeverMatchMethod(urlGlob, method))
		
		if (numMinArgs == method.params.size)
			return null
		
		routes	:= Route[,]
		numWild	:= 0
		for (i := 0; i < path.size; ++i) {
			if (path[i] == "*" || path[i] == "**") {
				if (numWild >= numMinArgs) {
					url := ``
					for (x := 0; x < i; ++x) {
						url = url.plusSlash.plusName(path[x])
					}
					routes.add(Route(url, response, httpMethods.join(" ")))
				}
				numWild++
			}
		}
		
		return routes
	}
	
	override Str toStr() {
		"${matchHint} : $responseHint"
	}
}

internal class RouteMatch {
    Obj		handler
	Str[]	canonical
    Obj[]	wildcards

	new make(Obj handler) {
		this.handler	= handler
		this.canonical	= Str[,]
		this.wildcards	= Obj[,]
	}

	Uri canonicalUrl() {
		url := ``
		for (i := 0; i < canonical.size; ++i) {
			url = url.plusSlash.plusName(canonical[i])
		}
		return url
	}
}