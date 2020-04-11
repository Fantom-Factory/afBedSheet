
** Matches HTTP Requests to response objects.
** 
** Regex Routes
** ************
** Matches the HTTP Request URL and HTTP Method to a response object using regular expressions.
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
**   Route(`/greet.*`, ...) 
** 
** will match the URLs '/greet.html', '/greet.php' but not '/greet'. 
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
** First a special *glob* syntax is used to capture string sections from the request URL.
** In stage 2 these strings are used as potential method arguments.
** 
** In brief, the special glob syntax is:
**  - '?' optionally matches the last character, 
**  - '/*' captures a path segment,
**  - '/**' captures all remaining path segments,
**  - '/***' captures the remaining URL.
** 
** Full examples follow:
** 
**   URL              glob          captures
**   ------------ --- ---------- -- -------------
**   /user/       --> /user/*    => null
**   /user/42     --> /user/*    => "42"
**   /user/42/    --> /user/*    => no match
**   /user/42/dee --> /user/*    => no match
**
**   /user/       --> /user/*/*  => no match
**   /user/42     --> /user/*/*  => no match
**   /user/42/    --> /user/*/*  => "42", null
**   /user/42/dee --> /user/*/*  => "42", "dee"
**
**   /user/       --> /user/**   => null
**   /user/42     --> /user/**   => "42"
**   /user/42/    --> /user/**   => "42", null
**   /user/42/dee --> /user/**   => "42", "dee"
**
**   /user/       --> /user/***  => null
**   /user/42     --> /user/***  => "42"
**   /user/42/    --> /user/***  => "42/"
**   /user/42/dee --> /user/***  => "42/dee"
** 
** Note that in stage 2, 'nulls' may be converted to empty strings. 
** 
** The intention of the '?' character is to optionally match a trailing slash. Example:
** 
**   URL              glob          captures
**   ------------ --- ---------- -- -------------
**   /index       --> /index/?   => match
**   /index/      --> /index/?   => match
**                vs      
**   /index       --> /index/    => no match
**   /index/      --> /index     => no match
**  
** Should a match be found, then the captured strings are further processed in stage 2.
** 
** A 'no match' signifies just that.
** 
** 
** 
** Stage 2 - Method Parameter Matching
** -----------------------------------
** An attempt is now made to match the captured strings to method parameters, taking into account nullable types 
** and default values.
** 
** First, the number of captured strings have to match the number of method parameters, taking into 
** account any optional / default values on the method.
** 
** Then the captured strings are converted into method arguments using the [ValueEncoder]`ValueEncoder` 
** service. If no value encoder is found then non-empty strings are converted using a [TypeCoercer]`afBeanUtils::TypeCoercer`.
** 
** 'null' values are passed through, or if the method parameter is not nullable, then [BeanFactory.defaultValue()]`afBeanUtils::BeanFactory.defaultValue` is used.
** 
** The above process may sound complicated but in practice it just works and does what you expect.
** 
** Here are a couple of examples:
** 
**   strings          method signature          args
**   ---------- --- ----------------------- -- ----------------
**   null       -->  (Str? a)               =>  null
**   "wotever"  -->  (Str? a)               =>  "wotever"
** 
**   null       -->  (Str a)                =>  ""
**   "wotever"  -->  (Str a)                =>  "wotever"
** 
**   null       -->  (Int? a)               =>  null
**   "68"       -->  (Int? a)               =>  68
** 
**   null       -->  (Int a)                =>  0
**   "68"       -->  (Int a)                =>  68
**   "wotever"  -->  (Int a)                =>  no match
** 
**   ""         -->  (Str? a, Int b := 68)  =>  null, (default)
**   ""         -->  (Str a, Int b := 68)   =>  "", (default)
** 
**              -->  (Obj a, Obj b)         =>  no match
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
const mixin Route {

	** Creates a Route that matches on the given URL glob pattern. 
	** 'urlGlob' must start with a slash "/". Example: 
	** 
	**   syntax: fantom 
	**   Route(`/index/**`)
	** 
	** Matching is made against URI patterns in [Fantom standard form]`sys::Uri` meaning 
	** delimiter characters in the path section will be escaped with a backslash, 
	** notably the ':/?#[]@\' characters. 
	** 
	** 'httpMethod' may specify multiple HTTP method separated by a space.
	**   
	**  - 'GET' 
	**  - 'GET HEAD'
	** 
	static new makeFromGlob(Uri urlGlob, Obj response, Str httpMethod := "GET") {
		RegexRoute(urlGlob, response, httpMethod)
	}

	** Returns a response object should the given uri (and http method) match this route. Returns 'null' if not.
	abstract Obj? match(HttpRequest httpRequest)
	
	** Returns a hint at what this route matches on. Used for debugging and in 404 / 500 error pages. 
	abstract Str matchHint()

	** Returns a hint at what response this route returns. Used for debugging and in 404 / 500 error pages. 
	abstract Str responseHint()
}
