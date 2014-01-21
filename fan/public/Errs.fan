using web::WebRes

** As thrown by BedSheet
const class BedSheetErr : Err {
	new make(Str msg := "", Err? cause := null) : super(msg, cause) {}
}

** Throw at any point to (re-)process / (re-)handle the wrapped response object. 
** Use to change the processing flow. 
const class ReProcessErr : Err {

	** The response object
	const Obj responseObj
	
	** Make a 'ReProcessErr' passing in a response obj to be processed. 
	new make(Obj responseObj, Err? cause := null) : super(msg, cause) {
		this.responseObj = responseObj
	}
}

** Throw at any point to (re-)process / (re-)handle the 'HttpStatus'. 
const class HttpStatusErr : ReProcessErr {
	new make(Int statusCode, Str statusMsg := WebRes.statusMsg[statusCode], Err? cause := null) : super(HttpStatus(statusCode, statusMsg), cause) { }
}

** Throw by the routing mechanism when converting uri segments to method params 
** 
** Extends `HttpStatusErr` so, by default, they cause a 404.
internal const class ValueEncodingErr : ReProcessErr {
	new make(Str msg := "", Err? cause := null) : super(HttpStatus(404, msg), cause) {}
}

