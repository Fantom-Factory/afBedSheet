
** Matches HTTP Requests to a response objects.
** 
** 'Route' is a mixin so you may provide your own implementations. The rest of this documentation 
** relates to the default implementation which uses regular expressions to match against the 
** Request URL and HTTP Method.
** 
** Regex Routes
** ************
** Matches the HTTP Request URL and HTTP Method to a response object using regular expressions.
** 
** Note that all URL matching is case-insensitive.
** 
** 
** Response Objects
** ================
** A 'Route' may return *any* response object, be it `Text`, `HttpStatus`, 'File', or any other.
** It simply returns whatever is passed into the ctor. 
** 
** Example, this matches the URL '/greet' and returns the string 'Hello Mum!'
** 
**   Route(`/greet`, Text.fromPlain("Hello Mum!")) 
** 
** And this redirects any request for '/home' to '/greet'
** 
**   Route(`/home`, Redirect.movedTemporarily(`/greet`)) 
** 
** You can use glob expressions in your URL, so:
** 
**   Route(`/greet.*`, ...) 
** 
** will match the URLs '/greet.html', '/greet.php' but not '/greet'. 
** 
** 
** 
** Response Methods
** ================
** Routes may also return `MethodCall` instances that call a Fantom method. 
** To use, pass in the method as the response object. 
** On a successful match, the 'Route' will convert the method into a 'MethodCall' object.
** 
**   Route(`/greet`, MyPage#Hello)
** 
** Method matching can also map URL path segments to method parameters and is a 2 stage process:
** 
** Stage 1 - URL Matching
** ----------------------
** First a special *glob* syntax is used to capture string sections from the request URL.
** In stage 2 these strings are used as potential method arguments.
** 
** In brief, the special glob syntax is:
**  - '?' optionally matches the last character, 
**  - '/*' captures a path segment,
**  - '/**' captures all path segments,
**  - '/***' captures the remaining URL.
** 
** Full examples follow:
** 
**   glob pattern     URL             captures
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
** 
** The intention of the '?' character is to optionally match a trailing slash. Example:
** 
**   glob         url
**   -----------------------------
**   /index/? --> /index  => match
**   /index/? --> /index/ => match
**   vs
**   /index/  --> /index  => no match
**   /index   --> /index/ => no match
**  
** Should a match be found, even if 'null' is captured, then the captured strings are further processed in stage 2.
** 
** A 'no match' signifies just that.
** 
** 
** 
** Stage 2 - Method Parameter Matching
** -----------------------------------
** An attempt is now made to match the captured string to method parameters, taking into account nullable types 
** and default values. 
** 
** In breif:
**  - method parameters with default values are considered optional,
**  - nullable method parameters may take, um, 'null'!
** 
** Full examples follow:
** 
**   method params             string args     match
**   --------------------------------------------------
**   Obj a, Obj b         -->               => no match  
**   Obj a, Obj b         -->  null         => no match
**   Obj a, Obj b         -->  null,  null  => no match 
**   Obj a, Obj b         --> "wot", "ever" => match
**   
**   Obj? a, Obj? b       -->               => no match
**   Obj? a, Obj? b       -->  null         => no match
**   Obj? a, Obj? b       -->  null,  null  => match
**   Obj? a, Obj? b       --> "wot", "ever" => match
**
**   Obj? a, Obj? b := "" -->               => no match
**   Obj? a, Obj? b := "" -->  null         => match
**   Obj? a, Obj? b := "" -->  null,  null  => match
**   Obj? a, Obj? b := "" --> "wot", "ever" => match
**
**   Obj? a, Obj b := ""  -->               => no match
**   Obj? a, Obj b := ""  -->  null         => match
**   Obj? a, Obj b := ""  -->  null,  null  => no match
**   Obj? a, Obj b := ""  --> "wot", "ever" => match
** 
** 'Obj' is used in the examples above, but method parameters can actually be *any* type.
** Captured strings are converted to the appropriate type by the [ValueEncoder]`ValueEncoder` 
** service.
** 
** Assuming you you have an entity object, such as 'User', with an ID field; you can contribute a 
** 'ValueEncoder' that inflates (or otherwise reads from a database) 'User' objects from a string 
** version of the ID. Then your methods can declare 'User' as a parameter and BedSheet will 
** convert the captured strings for you! 
** 
** Method parameters of type 'Str[]' are *capture all* parameters and will match the remaining URL (split on '/').
**
**  
** 
** Method Invocation
** -----------------
** Handler methods may be non-static. 
** They they belong to an IoC service then the service is obtained from the IoC registry.
** Otherwise the containing class is [autobuilt]`afIoc::Registry.autobuild`. 
** If the class is 'const', the instance is cached for future use.
** 
const mixin Route {
	
	@NoDoc @Deprecated { msg="Deprecated with no replacement. As Route is now a mixin, implementations matches may not be based on a regex." }
	virtual Regex routeRegex() { Str.defVal.toRegex }
	
	@NoDoc @Deprecated { msg="Deprecated with no replacement. As Route is now a mixin, implementations matches may not be based on HTTP methods." }
	virtual Str httpMethod() { Str.defVal }

	@NoDoc @Deprecated { msg="Deprecated with no replacement. As Route is now a mixin, implementations may generate dynamic responses." }
	virtual Obj response() { Str.defVal }

	** Creates a Route that matches on the given URL glob pattern. 
	** 'urlGlob' must start with a slash "/". Example: 
	** 
	**   Route(`/index/**`)
	** 
	** Note that matching is made against URI patterns in [Fantom standard form]`sys::Uri`. 
	** That means certain delimiter characters in the path section will be escaped with a 
	** backslash. Notably the ':/?#[]@\' characters. Glob expressions have to take account 
	** of this.   
	** 
	** 'httpMethod' may specify multiple HTTP methods, separated by spaces and / or commas.  
	** Each may also be a glob pattern. Example, all the following are valid:
	**  - 'GET' 
	**  - 'GET HEAD'
	**  - 'GET, HEAD'
	**  - 'GET, H*'
	** 
	** Use the simple string '*' to match all HTTP methods.
	static new makeFromGlob(Uri urlGlob, Obj response, Str httpMethod := "GET") {
		RegexRoute(urlGlob, response, httpMethod)
	}

	** For hardcore users; make a Route from a regex. Capture groups are used to match arguments.
	** Example:
	** 
	**   Route(Regex<|(?i)^\/index\/(.*?)$|>, #foo, "GET", true) ==> Route(`/index/**`)
	** 
	** Set 'matchAllSegs' to 'true' to have the last capture group mimic the glob '**' operator, 
	** splitting on "/" to match all remaining segments.  
	** 
	** Note that matching is made against URI patterns in [Fantom standard form]`sys::Uri`. 
	** That means certain delimiter characters in the path section will be escaped with a 
	** backslash. Notably the ':/?#[]@\' characters. Regular expressions have to take account 
	** of this.
	**    
	** 'httpMethod' may specify multiple HTTP methods, separated by spaces and / or commas.  
	** Each may also be a glob pattern. Example, all the following are valid:
	**  - 'GET' 
	**  - 'GET HEAD'
	**  - 'GET, HEAD'
	**  - 'GET, H*'
	** 
	** Use the simple string '*' to match all HTTP methods.
	static new makeFromRegex(Regex uriRegex, Obj response, Str httpMethod := "GET", Bool matchAllSegs := false) {
		RegexRoute(uriRegex, response, httpMethod, matchAllSegs)
	}

	** Returns a response object should the given uri (and http method) match this route. Returns 'null' if not.
	abstract Obj? match(HttpRequest httpRequest)
	
	** Returns a hint at what this route matches on. Used for debugging and in 404 / 500 error pages. 
	abstract Str matchHint()

	** Returns a hint at what response this route returns. Used for debugging and in 404 / 500 error pages. 
	abstract Str responseHint()
}

@NoDoc	// this class seems too important to keep internal!
const class RegexRoute : Route {
	private static const Str star	:= "(.*?)"

	** The uri regex this route matches.
	override const Regex routeRegex

	** The response to be returned from this route. 
	override const Obj response

	** HTTP method used for this route
	override const Str httpMethod

	private  const Regex[] 	httpMethodGlob
	private  const Bool		matchAllSegs
	private  const Bool		matchToEnd
	private  const Bool		isGlob
	internal const RouteResponseFactory	factory

	new makeFromGlob(Uri urlGlob, Obj response, Str httpMethod := "GET") {
	    if (urlGlob.scheme != null || urlGlob.host != null || urlGlob.port!= null )
			throw ArgErr(BsErrMsgs.route_shouldBePathOnly(urlGlob))
	    if (!urlGlob.isPathAbs)
			throw ArgErr(BsErrMsgs.route_shouldStartWithSlash(urlGlob))

		uriGlob	:= urlGlob.toStr
		regex	:= "(?i)^"
		uriGlob.each |c, i| {
			if (c.isAlphaNum || c == '?')
				regex += c.toChar
			else if (c == '*')  
				regex += star
			else 
				regex += ("\\" + c.toChar)
		}
		
		matchAllSegs	:= false
		matchToEnd		:= false
		if (uriGlob.endsWith("***")) {
			regex = regex[0..<-star.size*3] + "(.*)"
			matchToEnd	= true
			
		} else if (uriGlob.endsWith("**")) {
			regex = regex[0..<-star.size*2] + "(.*?)\\/?"
			matchAllSegs = true
		}
		
		regex += "\$"
		
		this.routeRegex 	= Regex.fromStr(regex)
		this.response 		= response
		this.factory 		= wrapResponse(response)
		this.httpMethod 	= httpMethod
		// split on both space and ','
		this.httpMethodGlob	= httpMethod.split.map { it.split(',') }.flatten.map { Regex.glob(it) }
		this.matchToEnd		= matchToEnd
		this.matchAllSegs	= matchAllSegs
		this.isGlob			= true
		this.factory.validate(routeRegex, urlGlob, matchAllSegs)
	}

	new makeFromRegex(Regex uriRegex, Obj response, Str httpMethod := "GET", Bool matchAllSegs := false) {
		this.routeRegex 	= uriRegex
		this.response 		= response
		this.factory 		= wrapResponse(response)
		this.httpMethod 	= httpMethod
		// split on both space and ','
		this.httpMethodGlob	= httpMethod.split.map { it.split(',') }.flatten.map { Regex.glob(it) }
		this.matchAllSegs	= matchAllSegs
		this.isGlob			= false
		this.factory.validate(routeRegex, null, matchAllSegs)
	}

	** Returns a response object should the given uri (and http method) match this route. Returns 'null' if not.
	override Obj? match(HttpRequest httpRequest) {
		if (!httpMethodGlob.any { it.matches(httpRequest.httpMethod) })
			return null

		segs := matchUri(httpRequest.url)
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

		if (matchAllSegs && !groups.isEmpty) {
			last := groups.removeAt(-1)
			groups.addAll(last.split('/'))
		}
		
		if (isGlob && !matchToEnd && !matchAllSegs && groups[-1].contains("/"))
			return null

		// convert empty Strs to nulls
		// see http://fantom.org/sidewalk/topic/2178#c14077
		// 'seg' needs to be named to return an instance of Str[], not Obj[] -> important for method injection
		return groups.map |Str seg->Str?| { seg.isEmpty ? null : seg }
	}

	private RouteResponseFactory wrapResponse(Obj response) {
		if (response.typeof.fits(RouteResponseFactory#))
			return response
		if (response.typeof.fits(Method#))
			return MethodCallFactory(response)
		return NoOpFactory(response)
	}
	
	override Str matchHint() {
		"${httpMethod} - ${routeRegex}"
	}
	
	override Str responseHint() {
		factory.toStr
	}
	
	override Str toStr() {
		"${httpMethod.justl(4)} - $routeRegex : $factory"
	}
}

** Keep public 'cos it could prove useful!
@NoDoc
const mixin RouteResponseFactory {
	abstract Bool matchSegments(Str?[] segments)

	** Obj?[] so we can easily add other args into the list
	abstract Obj? createResponse(Str?[] segments)

	virtual Void validate(Regex routeRegex, Uri? routeGlob, Bool matchAllSegs) { }

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

	override Void validate(Regex routeRegex, Uri? routeGlob, Bool matchAllSegs) {
		args := (Int) routeRegex.toStr.split('/').reduce(0) |Int count, arg -> Int| {
			count + (arg.contains(".*") ? 1 : 0)
		}
		if (args > method.params.size)
			throw ArgErr(BsErrMsgs.route_uriWillNeverMatchMethod(routeRegex, routeGlob, method))
		
		if (!matchAllSegs) {
			defs := (Int) method.params.reduce(0) |Int count, param -> Int| { count + (param.hasDefault ? 0 : 1) }
			if (args < defs)
				throw ArgErr(BsErrMsgs.route_uriWillNeverMatchMethod(routeRegex, routeGlob, method))
		}
	}

	override Str toStr() { "-> $method.qname" }
}

internal const class NoOpFactory : RouteResponseFactory {
	const Obj? response
	new make(Obj? response) { this.response = response }
	override Bool matchSegments(Str?[] segments) { true	}
	override Obj? createResponse(Str?[] segments) { response }
	override Str toStr() { response.toStr }
}
