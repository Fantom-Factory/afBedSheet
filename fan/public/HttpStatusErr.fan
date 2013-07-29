using web::WebRes

** Throw at any point to process / handle the wrapped `HttpStatus`.
const class HttpStatusErr : Err {

	** The HTTP (error) status.
	const HttpStatus httpStatus
	
	new make(Int statusCode, Str statusMsg := WebRes.statusMsg[statusCode], Err? cause := null) : super(msg, cause) {
		this.httpStatus = HttpStatus(statusCode, statusMsg, cause)
	}

	new makeFromHttpStatus(HttpStatus httpStatus) : super.make(httpStatus.msg, httpStatus.cause) {
		this.httpStatus = httpStatus
	}
}