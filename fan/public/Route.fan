
** Matches HTTP Requests to response objects.
** 
** URL matching is case-insensitive and trailing slashes that denote index or directory directory 
** pages are ignored.
** 
** 
** 
** Response Objects
** ================
** A 'Route' may return *any* response object, be it `Text`, `HttpStatus`, 'File', or any other.
** It simply returns whatever is passed into the ctor. 
** 
** Example, this matches the URL '/greet' and returns the string 'Hello Mum!'
** 
**   syntax: fantom 
**   Route(`/greet`, Text.fromPlain("Hello Mum!")) 
** 
** And this redirects any request for '/home' to '/greet'
** 
**   syntax: fantom 
**   Route(`/home`, Redirect.movedTemporarily(`/greet`)) 
** 
** You can use glob expressions in your URL, so:
** 
**   syntax: fantom 
**   Route(`/greet/*`, ...) 
** 
** 
** 
** Response Methods
** ================
** Routes may return `MethodCall` instances that call a Fantom method. 
** To use, pass in the method as the response object. 
** On a successful match, the 'Route' will convert the method into a 'MethodCall' object.
** 
**   syntax: fantom 
**   Route(`/greet`, MyPage#hello)
** 
** Method matching can also map URL path segments to method parameters and is a 2 stage process:
** 
** Stage 1 - URL Matching
** ----------------------
** Wildcards are used to capture string sections from the request URL to be used as method arguments.
** 
** Wildcard syntax is:
**  - '/*' captures a path segment
**  - '/**' captures all remaining path segments
** 
** Examples:
** 
**   URL              glob          captures
**   ------------ --- ---------- -- -------------
**   /user/       --> /user/*    => default(*)
**   /user/42     --> /user/*    => "42"
**   /user/42/    --> /user/*    => "42"
**   /user/42/dee --> /user/*    => no match
**
**   /user/       --> /user/**   => default(*)
**   /user/42     --> /user/**   => "42"
**   /user/42/    --> /user/**   => "42"
**   /user/42/dee --> /user/**   => "42/dee"
** 
** '(*)' If the corresponding method argument has a default value, it is taken, otherwise no match. 
** 
** Assuming you you have an entity object, such as 'User', with an ID field; you can contribute a 
** 'ValueEncoder' that inflates (or otherwise reads from a database) 'User' objects from a string 
** version of the ID. Then your methods can declare 'User' as a parameter and BedSheet will 
** convert the captured strings to User objects for you! 
** 
** 
** 
** Method Invocation
** -----------------
** Handler methods may be non-static. 
** They they belong to an IoC service then the service is obtained from the IoC registry.
** Otherwise the containing class is [autobuilt]`afIoc::Scope.build`. 
** If the class is 'const', the instance is cached for future use.
** 
const class Route {
	internal const Uri	_urlGlob
	internal const Str	_httpMethod
	internal const Obj	_response

	** Creates a Route that matches on the given URL glob pattern. 
	** 'urlGlob' must start with a slash "/". Example: 
	** 
	**   syntax: fantom 
	**   Route(`/index/**`)
	** 
	** 'httpMethod' may specify multiple HTTP method separated by a space.
	**   
	**   syntax: fantom 
	**   Route(`/index/**`, MyClass#myMethod, "GET HEAD")
	** 
	new make(Uri url, Obj response, Str httpMethod := "GET") {
		if (url.pathOnly != url)
			throw ArgErr("Route `$url` must only contain a path. e.g. `/foo/bar`")
		if (url.isPathRel)
			throw ArgErr("Route `$url` must start with a slash. e.g. `/foo/bar`")
		
		this._urlGlob		= url
		this._httpMethod	= httpMethod
		this._response		= response is Method ? RouteMethod(response) : response
	}

	** A hint at what this route matches on. Used for debugging and in 404 / 500 error pages. 
	virtual Str matchHint() {
		_httpMethod.justl(4) + " ${_urlGlob}"
	}

	** A hint at what response this route returns. Used for debugging and in 404 / 500 error pages. 
	virtual Str responseHint() {
		_response.toStr
	}

	** Creates additional Routes that match default method arguments
	@NoDoc	// I thought I'd need this for Pillow - I don't
	internal Route[]? _defRoutes(Method method) {
		path	:= _urlGlob.path
		numWildcards := 0
		for (i := 0; i < path.size; ++i) {
			if (path[i] == "*" || path[i] == "**")
				numWildcards++
		}
		if (numWildcards > method.params.size)
			throw ArgErr(msg_uriWillNeverMatchMethod(_urlGlob, method))
		
		numMinArgs := 0
		for (i := 0; i < method.params.size; ++i) {
			if (method.params[i].hasDefault == false)
				numMinArgs++
		}
		if (numWildcards < numMinArgs)
			throw ArgErr(msg_uriWillNeverMatchMethod(_urlGlob, method))
		
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
					routes.add(Route(url, _response, _httpMethod))
				}
				numWild++
			}
		}
		
		return routes
	}
	
	override Str toStr() {
		"${matchHint} : ${responseHint}"
	}
	
	private static Str msg_uriWillNeverMatchMethod(Uri url, Method method) {
		"Route URL `${url}` will never match method ${method.parent.qname} " + method.signature.replace("sys::", "")
	}
}
