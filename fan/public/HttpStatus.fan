using web::WebRes

** Return from request handlers to send the appropriate response to the client.
const class HttpStatus {

	** The HTTP status code.
	** 
	** @see `web::WebRes.statusMsg`
	const Int code
	
	** The HTTP status message.
	** 
	** @see `web::WebRes.statusMsg`
	const Str msg
	
	** The Err which caused this http status. Generally used with a HTTP Status Code of 500. 
	const Err? cause
	
	new make(Int statusCode, Str statusMsg := WebRes.statusMsg[statusCode], Err? cause := null) {
		this.code 	= statusCode
		this.msg 	= statusMsg
		this.cause 	= cause
	}
}
