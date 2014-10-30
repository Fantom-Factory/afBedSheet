using web::WebRes

** (Response Object) Use to send a generic HTTP Status to the client.
** 
**   HttpStatus(404, "Page Not Found")
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
	
	override Str toStr() {
		"${code} - ${msg}"
	}
}
