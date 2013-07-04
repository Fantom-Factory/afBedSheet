
**
** Matches uri paths to handler methods, converting any remaining path segments into method 
** arguments. Method arguments with default values are mapped to optional path segments. Example:
** 
** pre>
** using afBedSheet
** using afIoc
** 
** class AppModule {
**   @Contribute
**   static Void contributeRoutes(OrderedConfig conf) {
**     conf.add(ArgRoute(`/hello`, HelloPage#hello))
**   }
** }
** 
** class HelloPage {
**   TextResult hello(Str name, Int iq := 666) {
**     return TextResult.fromPlain("Hello! I'm $name and I have an IQ of $iq!")
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
** > TIP: Contribute 'ValueEncoders' to convert path into Entities. BedSheet can then call handlers 
** with real Entities, not just str IDs!
** 
** Parameters of type 'Uri' or 'Str[]' are *capture all* parameters and match the whole uri.
**
** Request uri's (for matching purposes) are treated as case-insensitive. In the example above, both
** 
**  - 'hello/Luci' and 
**  - 'HELLO/Luci' 
**
** would be matched.
** 
** If a handler class is a service, it is obtained from the IoC registry, otherwise it is
** [autobuilt]`afIoc::Registry.autobuild`. If the class is 'const', the instance is cached for 
** future use.
** 
class Route {

	** The uri regex this route matches.
	const Regex routeRegex

	** Method handler for this route. 
	const Method handler

	** HTTP method used for this route
	const Str httpMethod

	private const Regex[] 	httpMethodGlob
	private const Bool		matchAllArgs

	**
	** 'glob' must start with a slash "/"
	** 
	** 'httpMethod' may be a glob. Example, use "*" to match all methods.
	** 
	** case-insensitive
	new makeFromGlob(Uri glob, Method handler, Str httpMethod := "GET") {
	    if (glob.scheme != null || glob.host != null || glob.port!= null )
			throw BedSheetErr(BsMsgs.routeShouldBePathOnly(glob))
	    if (!glob.isPathAbs)
			throw BedSheetErr(BsMsgs.routeShouldStartWithSlash(glob))

		uriGlob	:= glob.toStr
		skip 	:= false
		regex	:= "(?i)^"
		uriGlob.each |c, i| {
			if (skip) {
				skip = false
				return
			}
			if (c.isAlphaNum || c == '?')
				regex += c.toChar
			else if (c == '*')  {
				if (i < (uriGlob.size-1) && uriGlob[i+1] == '*') {
					// match all args
					regex += "(.*?)\\/?"
					skip = true
				} else
					regex += "(.*?)"
			}
			else regex += ("\\" + c.toChar)
		}
		regex += "\$"

		this.routeRegex 	= Regex.fromStr(regex)
		this.handler 		= handler
		this.httpMethod 	= httpMethod
		// split on both space and ','
		this.httpMethodGlob	= httpMethod.split.map { it.split(',') }.flatten.map { Regex.glob(it) }
		this.matchAllArgs	= uriGlob.endsWith("**")
	}

	** TODO: check syntax for eg. Route(Regex<| blah |>)
	new makeFromRegex(Regex uriRegex, Method handler, Str httpMethod := "GET") {
		this.routeRegex 	= uriRegex
		this.handler 		= handler
		this.httpMethod 	= httpMethod
		// split on both space and ','
		this.httpMethodGlob	= httpMethod.split.map { it.split(',') }.flatten.map { Regex.glob(it) }
		// TODO: check this works
		this.matchAllArgs	= uriRegex.toStr.endsWith("**") || uriRegex.toStr.endsWith("**\$")
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
		
		if (!matchAllArgs && groups[-1].contains("/"))
			return null
						
		return groups
	}
	
	** Returns null if uriSegments do not match (optional) method handler arguments
	internal Str[]? matchArgs(Str[] uriSegments) {
		if (handler.params.size == uriSegments.size)
			return uriSegments
		
		// FIXME: allow nulls as well as defaults
		paramRange	:= (handler.params.findAll { !it.hasDefault }.size..<handler.params.size)
		if (paramRange.contains(uriSegments.size))
			return uriSegments

		return null
	}

	override Str toStr() {
		"Route:$routeRegex - $httpMethod -> $handler.qname"
	}
}
