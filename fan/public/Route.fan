
**
** Matches uri paths to request handler methods. Any remaining path segments are converted into method 
** arguments. Use '*' to capture (non-greedy) method arguments, '**' to capture all remaining path 
** segments and '***' to capture the remaining url. Examples:
** 
** pre>
**   glob pattern     uri             arguments
**   --------------------------------------------
**   /user/*      --> /user/       => null
**   /user/*      --> /user/42     => "42"
**   /user/*      --> /user/42/    => no match
**   /user/*      --> /user/42/dee => no match
**
**   /user/*/*    --> /user/       => no match
**   /user/*/*    --> /user/42     => no match
**   /user/*/*    --> /user/42/    => "42", null
**   /user/*/*    --> /user/42/dee => "42", "dee"
** 
**   /user/**     --> /user/       => null
**   /user/**     --> /user/42     => "42"
**   /user/**     --> /user/42/    => "42"
**   /user/**     --> /user/42/dee => "42", "dee"
**
**   /user/***    --> /user/       => null
**   /user/***    --> /user/42     => "42"
**   /user/***    --> /user/42/    => "42/"
**   /user/***    --> /user/42/dee => "42/dee"
** <pre
** 
** The argument list is then matched to the method parameters, taking into account nullable types 
** and default values. Examples:
** 
** pre>
**   method params             arguments       match
**   --------------------------------------------------
**   Str a, Str b         -->               => no match  
**   Str a, Str b         -->  null         => no match
**   Str a, Str b         -->  null,  null  => no match 
**   Str a, Str b         --> "wot", "ever" => match
**   
**   Str? a, Str? b       -->               => no match
**   Str? a, Str? b       -->  null         => no match
**   Str? a, Str? b       -->  null,  null  => match
**   Str? a, Str? b       --> "wot", "ever" => match
**
**   Str? a, Str? b := "" -->               => no match
**   Str? a, Str? b := "" -->  null         => match
**   Str? a, Str? b := "" -->  null,  null  => match
**   Str? a, Str? b := "" --> "wot", "ever" => match
**
**   Str? a, Str b := ""  -->               => no match
**   Str? a, Str b := ""  -->  null         => match
**   Str? a, Str b := ""  -->  null,  null  => no match
**   Str? a, Str b := ""  --> "wot", "ever" => match
** <pre
** 
** Method parameters can be any Obj (and not just 'Str') as they are converted using the  
** [ValueEncoder]`ValueEncoder` service.
**  
** > TIP: Contribute 'ValueEncoders' to convert path segments into Entities. This means BedSheet can
** call handlers with real entities, not just str IDs!
** 
** Parameters of type 'Str[]' are *capture all* parameters and match the remaining uri (split on '/').
**
** Request uri's (for matching purposes) are treated as case-insensitive. 
** 
** Use '?' to optional match the last character. Use to optionally match a trailing slash. e.g.
** 
** pre>
**   glob         uri
**   -----------------------------
**   /index/? --> /index  => match
**   /index/? --> /index/ => match
**   vs
**   /index/  --> /index  => no match
**   /index   --> /index/ => no match
** <pre
** 
** If a handler class is a service, it is obtained from the IoC registry, otherwise it is
** [autobuilt]`afIoc::Registry.autobuild`. If the class is 'const', the instance is cached for 
** future use.
** 
const class Route {
	private static const Str star	:= "(.*?)"
	** The uri regex this route matches.
	const Regex routeRegex

	** The response to be returned from this route. 
	const Obj response

	** HTTP method used for this route
	const Str httpMethod

	private const Regex[] 	httpMethodGlob
	private const Bool		matchAllArgs
	private const Bool		matchToEnd
	private const Bool		isGlob
	private const RouteResponseFactory	factory

	** Make a Route that matches on the given glob pattern.
	** 
	** 'glob' must start with a slash "/"
	** 
	** 'httpMethod' may be a glob. Example, use "*" to match all methods.
	new makeFromGlob(Uri glob, Obj response, Str httpMethod := "GET") {
	    if (glob.scheme != null || glob.host != null || glob.port!= null )
			throw BedSheetErr(BsErrMsgs.routeShouldBePathOnly(glob))
	    if (!glob.isPathAbs)
			throw BedSheetErr(BsErrMsgs.routeShouldStartWithSlash(glob))

		uriGlob	:= glob.toStr
		regex	:= "(?i)^"
		uriGlob.each |c, i| {
			if (c.isAlphaNum || c == '?')
				regex += c.toChar
			else if (c == '*')  
				regex += star
			else 
				regex += ("\\" + c.toChar)
		}
		
		matchRemaining	:= false
		matchToEnd		:= false
		if (uriGlob.endsWith("***")) {
			regex = regex[0..<-star.size*3] + "(.*)"
			matchToEnd	= true
			
		} else if (uriGlob.endsWith("**")) {
			regex = regex[0..<-star.size*2] + "(.*?)\\/?"
			matchRemaining = true
		}
		
		regex += "\$"
		
		this.routeRegex 	= Regex.fromStr(regex)
		this.response 		= response
		this.factory 		= wrapResponse(response)
		this.httpMethod 	= httpMethod
		// split on both space and ','
		this.httpMethodGlob	= httpMethod.split.map { it.split(',') }.flatten.map { Regex.glob(it) }
		this.matchToEnd		= matchToEnd
		this.matchAllArgs	= matchRemaining
		this.isGlob			= true
	}

	** For hardcore users; make a Route from a regex. Capture groups are used to match arguments.
	** Example:
	** 
	**   Route(Regex<|(?i)^\/index\/(.*?)$|>, #foo, "GET", true) -> Route(`/index/**`)
	** 
	** Set 'matchRemaining' to 'true' to have the last capture group mimic the glob '**' operator, 
	** splitting on "/" to match all remaining segments.  
	new makeFromRegex(Regex uriRegex, Obj response, Str httpMethod := "GET", Bool matchRemaining := false) {
		this.routeRegex 	= uriRegex
		this.response 		= response
		this.factory 		= wrapResponse(response)
		this.httpMethod 	= httpMethod
		// split on both space and ','
		this.httpMethodGlob	= httpMethod.split.map { it.split(',') }.flatten.map { Regex.glob(it) }
		this.matchAllArgs	= matchRemaining
		this.isGlob			= false
	}

	** Returns a response object should the given uri (and http method) match this route. Returns 'null' if not.
	Obj? match(Uri uri, Str httpMethod) {
		if (!httpMethodGlob.any { it.matches(httpMethod) })
			return null

		segs := matchUri(uri)
		if (segs == null)
			return null

		if (!factory.matchSegments(segs))
			return null
		
		return factory.createResponse(segs)
	}

	** Returns null if the given uri does not match the uri regex
	internal Str?[]? matchUri(Uri uri) {
		matcher := routeRegex.matcher(uri.pathOnly.toStr)
		find := matcher.find 
		if (!find)
			return null
		
		groups := Str[,]
		
		// use find as supplied Regex may not have ^...$
		while (find) {
			groupCunt := matcher.groupCount
			if (groupCunt == 0)
				return Str#.emptyList
			
			(1..groupCunt).each |i| {
				g := matcher.group(i)
				groups.add(g)
			}
		
			find = matcher.find
		}

		if (matchAllArgs && !groups.isEmpty) {
			last := groups.removeAt(-1)
			groups.addAll(last.split('/'))
		}
		
		if (isGlob && !matchToEnd && !matchAllArgs && groups[-1].contains("/"))
			return null

		// convert empty Strs to nulls
		// see http://fantom.org/sidewalk/topic/2178#c14077
		// 'seg' needs to be named to return an instance of Str[], not Obj[] -> important for method injection
		return groups.map |Str seg->Str| { seg.isEmpty ? null : seg }
	}

	private RouteResponseFactory wrapResponse(Obj response) {
		if (response.typeof.fits(RouteResponseFactory#))
			return response
		if (response.typeof.fits(Method#))
			return MethodCallFactory(response)
		return NoOpFactory(response)
	}
	
	override Str toStr() {
		"Route:$routeRegex - $httpMethod -> ${response.typeof.name}: ${response.toStr}"
	}
}

** Keep public 'cos it could prove useful!
@NoDoc
const mixin RouteResponseFactory {
	abstract Bool matchSegments(Str?[] segments)

	** Obj?[] so we can easily add other args into the list
	abstract Obj? createResponse(Str?[] segments)
	
	static Bool matchesMethod(Method method, Str?[] segments) {
		if (segments.size > method.params.size)
			return false
		return method.params.all |Param param, i->Bool| {
			if (i >= segments.size)
				return param.hasDefault
			return (segments[i] == null) ? param.type.isNullable : true
		}
	}

	static Bool matchesParams(Type[] params, Str?[] segments) {
		if (segments.size > params.size)
			return false
		return params.all |Type param, i->Bool| {
			if (i >= segments.size)
				return false
			return (segments[i] == null) ? param.isNullable : true
		}
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
}

internal const class NoOpFactory : RouteResponseFactory {
	const Obj? response
	new make(Obj? response) { this.response = response }
	override Bool matchSegments(Str?[] segments) { true	}
	override Obj? createResponse(Str?[] segments) { response }
}
