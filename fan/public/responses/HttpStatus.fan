
** (Response Object) -
** Use to send a generic HTTP Status to the client.
**
**   syntax: fantom
**   HttpStatus(404, "Page Not Found")
const class HttpStatus {

	** The HTTP status code.
	**
	** @see `HttpResponse.statusMsg`
	const Int code

	** The HTTP status message.
	**
	** @see `HttpResponse.statusMsg`
	const Str msg

	** Custom user data
	const Obj? data

	new make(Int statusCode, Str? statusMsg := HttpResponse.statusMsg[statusCode], Obj? data := null) {
		this.code 	= statusCode
		this.msg 	= statusMsg ?: ""	// makes life easier if msg is not-null - see BedSheetPagesImpl
		this.data 	= data.toImmutable
	}

	** Throw to send a HTTP Status to the client.
	** Use in exceptional cases where it may not be suitable / possible to return a 'HttpStatus' instance.
	**
	**   syntax: fantom
	**   throw HttpStatus.makeErr(404, "Page Not Found")
	** 
	** *Consider using 'toErr()' instead.*
	static ReProcessErr makeErr(Int statusCode, Str? statusMsg := HttpResponse.statusMsg[statusCode], Obj? data := null) {
		ReProcessErr(HttpStatus(statusCode, statusMsg, data))
	}

	** Convert this status to an Err to be thrown.
	** Use in exceptional cases where it may not be suitable / possible to return a 'HttpStatus' instance.
	**
	**   syntax: fantom
	**   throw HttpStatus(404, "Page Not Found").toErr
	ReProcessErr toErr() {
		ReProcessErr(this)
	}

	** Returns '${code} - ${msg}'
	override Str toStr() {
		msg.trimToNull == null ? code.toStr : "${code} - ${msg}"
	}
}
