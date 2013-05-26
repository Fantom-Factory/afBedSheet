using web::WebRes

** As thrown by BedSheet
const class BedSheetErr : Err {
	new make(Str msg := "", Err? cause := null) : super(msg, cause) {}
}

** Throw at any point to return / handle the http status
const class HttpErr : BedSheetErr {
	** The HTTP (error) status code for this error.
	** 
	** @see `web::WebRes.statusMsg`
	const Int statusCode
	
	new make(Int statusCode, Str msg := WebRes.statusMsg[statusCode], Err? cause := null) : super(msg, cause) {
		this.statusCode = statusCode
	}
}

