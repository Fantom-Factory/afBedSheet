using afBeanUtils::NotFoundErr

** As thrown by BedSheet
const class BedSheetErr : Err {
	new make(Str msg := "", Err? cause := null) : super(msg, cause) {}
}

** Throw to process / handle the wrapped BedSheet response object. 
** Use to change the processing flow. Often used to send a redirect to the client,
** example:
**
**   syntax: fantom 
**   throw ReProcessErr(Redirect.movedTemporarily(`/admin/login`))
const class ReProcessErr : Err {
	
	** I'm not proud of this but some response objs just aren't const (e.g. Pillow PageMeta)
	** And as far as BedSheet is concerned - it *will* be processed in the same thread.
	** I don't want to chance using LocalRefs, for if it does transcend threads (by other means),
	** then I won't be able to re-claim it!
	private const Unsafe responseObjRef

	** The response object
	Obj responseObj() {
		responseObjRef.val
	}
	
	** Make a 'ReProcessErr' passing in a response obj to be processed. 
	new make(Obj responseObj, Err? cause := null) : super(msg, cause) {
		this.responseObjRef = Unsafe(responseObj)
	}

	** Make a 'ReProcessErr' passing in a response obj to be processed. 
	new makeWithMsg(Obj responseObj, Str msg, Err? cause := null) : super.make(msg, cause) {
		this.responseObjRef = Unsafe(responseObj)
	}
}

** Throw to process / handle the wrapped 'HttpStatus' object. Often used to return a 
** 404 to the client, example:
** 
**   throw HttpStatusErr(404, "Page not found")
@NoDoc @Deprecated { msg="Use 'HttpStatus.makeErr(...)' instead" } 
const class HttpStatusErr : ReProcessErr {
	new make(Int statusCode, Str statusMsg := HttpResponse.statusMsg[statusCode], Err? cause := null) : super.makeWithMsg(HttpStatus(statusCode, statusMsg), statusMsg, cause) { }
}

** Throw by the routing mechanism / 'ValueEncoders' when converting URI segments to method params.
@NoDoc	// referenced by afPillow::Pages.convertArgs()
const class ValueEncodingErr : BedSheetErr {
	new make(Str msg := "", Err? cause := null) : super(msg, cause) { }
}

** A generic 'NotFoundErr'.
internal const class BedSheetNotFoundErr : ArgErr, NotFoundErr {
	override const Str?[] availableValues
	
	new make(Str msg, Obj?[] availableValues, Err? cause := null) : super(msg, cause) {
		this.availableValues = availableValues.map { it?.toStr }.sort
	}
	
	override Str toStr() {
		NotFoundErr.super.toStr		
	}
}

internal const class UnknownResponseObjectErr : Err, NotFoundErr {
	override const Str?[]	availableValues
	override const Str 		valueMsg := "Known Response Objects:"
	
	new make(Str msg, Obj?[] availableValues, Err? cause := null) : super(msg, cause) {
		this.availableValues = availableValues.map { it?.toStr }.sort
	}
	
	override Str toStr() {
		NotFoundErr.super.toStr
	}
}