using web::WebRes

** As thrown by BedSheet
const class BedSheetErr : Err {
	new make(Str msg := "", Err? cause := null) : super(msg, cause) {}
}

** Throw at any point to return / handle the http status.
** 
** By default the Err msg is sent to the client. 
** 
** Note there's a fine line between helping the developer and helping a hacker, so be careful what 
** msgs you construct your `HttpStatusErr` with!
** 
const class HttpStatusErr : BedSheetErr {
	
	** The HTTP (error) status code for this error.
	** 
	** @see `web::WebRes.statusMsg`
	const Int statusCode
	
	new make(Int statusCode, Str msg := WebRes.statusMsg[statusCode], Err? cause := null) : super(msg, cause) {
		this.statusCode = statusCode
	}
}

