using web::WebRes

** (Response Object) - 
** Use to send a generic HTTP Status to the client.
** 
**   syntax: fantom
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
	
	** Throw to send a HTTP Status to the client. 
	** Use in exceptional cases where it may not be suitable / possible to return a 'HttpStatus' instance.
	** 
	**   syntax: fantom
	**   throw HttpStatus.makeErr(404, "Page Not Found")
	static ReProcessErr makeErr(Int statusCode, Str statusMsg := WebRes.statusMsg[statusCode], Err? data := null) {
		ReProcessErr(HttpStatus(statusCode, statusMsg, data))
	}

	** Returns '${code} - ${msg}'
	override Str toStr() {
		"${code} - ${msg}"
	}
}
