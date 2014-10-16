
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
