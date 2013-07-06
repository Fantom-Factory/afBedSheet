
** Matches uri paths to handler methods, converting any remaining path segments into method 
** arguments. Use '*' to capture (non-greedy) method arguments, '**' to capture all 
** remaining path segments and '***' to capture the remaining url Examples:
** 
** pre>
**   glob pattern     uri             arguments
**   -----------------------------------------------------
**   /user/*      --> /user/       => ""
**   /user/*      --> /user/42     => "42"
**   /user/*      --> /user/42/dee => no match
**
**   /user/*/*    --> /user/       => no match
**   /user/*/*    --> /user/42     => no match
**   /user/*/*    --> /user/42/dee => "42", "dee"
** 
**   /user/**     --> /user/       => ""
**   /user/**     --> /user/42     => "42"
**   /user/**     --> /user/42/dee => "42", "dee"
**
**   /user/***    --> /user/       => ""
**   /user/***    --> /user/42     => "42"
**   /user/***    --> /user/42/dee => "42/dee"
** <pre
** 
** Method arguments with default values are mapped to optional path segments. Use '**' to capture 
** optional segments in the uri. Example:
** 
** pre>
** using afBedSheet
** using afIoc
** 
** class AppModule {
**   @Contribute
**   static Void contributeRoutes(OrderedConfig conf) {
**     conf.add(Route(`/hello/**`, HelloPage#hello))
**   }
** }
** 
** class HelloPage {
**   TextResponse hello(Str name, Int iq := 666) {
**     return TextResponse.fromPlain("Hello! I'm $name and I have an IQ of $iq!")
**   }
** }
** 
** '/hello/Traci/69' => helloPage.hello("Traci", 69) => "Hello! I'm Traci and I have an IQ of 69"
** 'hello/Luci'      => helloPage.hello("Luci")      => "Hello! I'm Luci and I have an IQ of 666"
** 'dude/'           => no match
** 'hello/'          => no match
** 'hello/1/2/3      => no match
** <pre
** 
** Path segments are converted to Objs via the [ValueEncoder]`ValueEncoder` service.
**  
** > TIP: Contribute 'ValueEncoders' to convert path segments into Entities. BedSheet can then call 
** handlers with real Entities, not just str IDs!
** 
** Parameters of type 'Str[]' are *capture all* parameters and match the remaining uri (split on '/').
**
** Request uri's (for matching purposes) are treated as case-insensitive. In the example above, both
** 
**  - 'hello/Luci' and 
**  - 'HELLO/Luci' 
**
** would be matched.
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
** Note: There is no special handling for nullable types in handler method arguments as BedSheet 
** can not determine when 'null' is a suitable replacement for an empty str. Instead contribute a
** `ValueEncoder` or use default values.
** 
const class Route {
	private static const Str star	:= "(.*?)"
	** The uri regex this route matches.
	const Regex routeRegex

	** Method handler for this route. 
	const Method handler

	** HTTP method used for this route
	const Str httpMethod

	private const Regex[] 	httpMethodGlob
	private const Bool		matchAllArgs
	private const Bool		matchToEnd
	private const Bool		isGlob

	** Make a Route that matches on the given glob pattern.
	** 
	** 'glob' must start with a slash "/"
	** 
	** 'httpMethod' may be a glob. Example, use "*" to match all methods.
	new makeFromGlob(Uri glob, Method handler, Str httpMethod := "GET") {
	    if (glob.scheme != null || glob.host != null || glob.port!= null )
			throw BedSheetErr(BsMsgs.routeShouldBePathOnly(glob))
	    if (!glob.isPathAbs)
			throw BedSheetErr(BsMsgs.routeShouldStartWithSlash(glob))

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
		this.handler 		= handler
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
	new makeFromRegex(Regex uriRegex, Method handler, Str httpMethod := "GET", Bool matchRemaining := false) {
		this.routeRegex 	= uriRegex
		this.handler 		= handler
		this.httpMethod 	= httpMethod
		// split on both space and ','
		this.httpMethodGlob	= httpMethod.split.map { it.split(',') }.flatten.map { Regex.glob(it) }
		this.matchAllArgs	= matchRemaining
		this.isGlob			= false
	}

	internal Str[]? match(Uri uri, Str httpMethod) {
		if (!httpMethodGlob.any { it.matches(httpMethod) })
			return null

		segs := matchUri(uri)
		if (segs == null)
			return null
		
		args := matchArgs(segs)
		if (args == null)
			return null
		
		return args
	}

	** Returns null if the given uri does not match the uri regex
	internal Str[]? matchUri(Uri uri) {
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
						
		return groups
	}
	
	** Returns null if uriSegments do not match (optional) method handler arguments
	internal Str[]? matchArgs(Str[] uriSegments) {
		if (handler.params.size == uriSegments.size)
			return uriSegments
		
		paramRange	:= (handler.params.findAll { !it.hasDefault }.size..<handler.params.size)
		if (paramRange.contains(uriSegments.size))
			return uriSegments

		return null
	}

	override Str toStr() {
		"Route:$routeRegex - $httpMethod -> $handler.qname"
	}
}
