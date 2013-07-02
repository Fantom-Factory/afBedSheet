
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
**   static Void contributeRoutes(OrderedConfig config) {
**     config.addUnordered(ArgRoute(`/hello`, HelloPage#hello))
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
** 'hello/'          => RouteNotFoundErr
** 'hello/1/2/3      => RouteNotFoundErr
** 'dude'            => no match
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
const class ArgRoute {

	** The URI this route matches. Always starts and ends with a slash.
	const Uri routeBase

	** Method handler for this route. 
	const Method handler

	** HTTP method used for this route
	const Str httpMethod

	private const Str[] matchingPath
	private const Regex[] httpMethodGlob
	
	** 'routeBase' should start with a slash "/"
	** 
	** 'httpMethod' may be a glob. Example, use "*" to match all methods.
	new make(Uri routeBase, Method handler, Str httpMethod := "GET") {
	    if (!routeBase.isPathOnly)
			throw BedSheetErr(BsMsgs.routeShouldBePathOnly(routeBase))
	    if (!routeBase.isPathAbs)
			throw BedSheetErr(BsMsgs.routeShouldStartWithSlash(routeBase))

		this.routeBase 		= routeBase.plusSlash
		this.httpMethod		= httpMethod.upper.trim
		this.handler 		= handler
		this.matchingPath 	= routeBase.path.map { it.lower }
		// split on both space and ','
		this.httpMethodGlob	= httpMethod.split.map { it.split(',') }.flatten.map { Regex.glob(it) } 
	}

	internal Uri? match(Uri uri, Str httpMethod) {
		if (!httpMethodGlob.any { it.matches(httpMethod) })
			return null

		uriPath := uri.path
		if (matchingPath.size > uriPath.size)
			return null
		
		actualBase	:= ``	// need to build up the actualBase for a case-insensitive Uri.relTo()
		match		:= matchingPath.all |path, i| { 
			actualBase = actualBase.plusSlash.plusName(uriPath[i]) 
			return path == uriPath[i].lower
		}
		if (!match) 
			return null

		routeRel	:= uri.relTo(actualBase)
		return routeRel
	}
	
	internal Str[] argList(Uri routeRel) {
		routePath	:= routeRel.path
		if (handler.params.size == routePath.size)
			return routePath
		
		paramRange	:= (handler.params.findAll { !it.hasDefault }.size..<handler.params.size)
		if (paramRange.contains(routePath.size))
			return routePath

		throw RouteNotFoundErr(BsMsgs.handlerArgSizeMismatch(handler, routeRel))
	}
	
	override Str toStr() {
		"ArgRoute:$routeBase - $httpMethod -> $handler.qname"
	}
}
