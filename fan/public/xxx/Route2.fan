
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
		
		// FIXME sort out this shite!
//		this.factory 		= wrapResponse(response).validate(urlGlob)
	}

//	@NoDoc @Deprecated
//	Obj? match(HttpRequest httpRequest) { null }
//	
//	private RouteResponseFactory wrapResponse(Obj response) {
//		if (response.typeof.fits(RouteResponseFactory#))
//			return response
//		if (response.typeof.fits(Method#))
//			return MethodCallFactory(response)
//		return NoOpFactory(response)
//	}
	
	override Str toStr() {
		"${matchHint} : $responseHint"
	}
}

** Keep public cos it could prove useful!
@NoDoc
const mixin RouteResponseFactory {

	abstract Bool matchSegments(Str?[] segments)

	abstract Obj? createResponse(Str?[] segments)

	virtual This validate(Uri url) { this }

	** Helper method for subclasses
	static Bool matchesMethod(Method method, Str?[] segments) {
		if (segments.size > method.params.size)
			return false
		
		for (i := 0; i < method.params.size; ++i) {
			param := method.params[i]
			
			if (i >= segments.size && !param.hasDefault)
				return false
			
			if (segments[i] == null && !param.type.isNullable) {
				// convert nulls to "" and let the valueEncoder convert
				segments[i] = ""
			}
		}
		return true
	}

	** Helper method for subclasses
	static Bool matchesParams(Type[] paramTypes, Str?[] segments) {
		if (segments.size > paramTypes.size)
			return false

		for (i := 0; i < paramTypes.size; ++i) {
			paramType := paramTypes[i]

			if (i >= segments.size)
				return false

			if (segments[i] == null && !paramType.isNullable)
				return false
		}
		return true
	}
}

internal const class MethodCallFactory : RouteResponseFactory {
	const Method method
	
	new make(Method method) {
		this.method = method
	}
	
	override Bool matchSegments(Str?[] segments) {
		matchesMethod(method, segments)
	}

	override Obj? createResponse(Str?[] segments) {
		MethodCall(method, segments)
	}

	override This validate(Uri url) {
		path := url.path
		numWildcards := 0
		for (i := 0; i < path.size; ++i) {
			if (path[i] == "*" || path[i] == "**")
				numWildcards++
		}
		if (numWildcards > method.params.size)
			throw ArgErr(BsErrMsgs.route_uriWillNeverMatchMethod(url, method))
		
		numMinArgs := 0
		for (i := 0; i < method.params.size; ++i) {
			if (method.params[i].hasDefault == false)
				numMinArgs++
		}
		if (numWildcards < numMinArgs)
			throw ArgErr(BsErrMsgs.route_uriWillNeverMatchMethod(url, method))
		
		return this
	}

	override Str toStr() { "-> ${method.qname}()" }
}

internal const class NoOpFactory : RouteResponseFactory {
	const Obj? response
	new make(Obj? response) { this.response = response }
	override Bool matchSegments(Str?[] segments) { true	}
	override Obj? createResponse(Str?[] segments) { response }
	override Str toStr() { response.toStr }
}


@Deprecated
class Route3 {
    Obj		handler
	Uri		requestUrl
    Uri		canonicalUrl
    Str[]	wildcardSegments

	new make(Uri requestUrl, Uri canonicalUrl, Obj handler, Str[] wildcardSegments) {
		this.requestUrl = requestUrl
		this.canonicalUrl = canonicalUrl
		this.handler = handler
		this.wildcardSegments = wildcardSegments
	}
}

internal class Route4 {
    Obj		handler
	Str[]	canonical
    Obj[]	wildcards
//    Str[]	remaining

	new make(Obj handler) {
		this.handler	= handler
		this.canonical	= Str[,]
		this.wildcards	= Obj[,]
//		this.remaining	= Str[,]
	}

	Uri canonicalUrl() {
		url := ``
		for (i := 0; i < canonical.size; ++i) {
			url = url.plusSlash.plusName(canonical[i])
		}
		return url
	}
}