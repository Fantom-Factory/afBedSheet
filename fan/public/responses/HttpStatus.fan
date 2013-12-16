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
	
	** Custom user data 
	const Obj? data
	
	new make(Int statusCode, Str statusMsg := WebRes.statusMsg[statusCode], Err? data := null) {
		this.code 	= statusCode
		this.msg 	= statusMsg
		this.data 	= data
	}
}
