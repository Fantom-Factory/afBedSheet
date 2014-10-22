using afBeanUtils::NotFoundErr
using web::WebRes

** As thrown by BedSheet
const class BedSheetErr : Err {
	new make(Str msg := "", Err? cause := null) : super(msg, cause) {}
}

** Throw at any point to (re)process / (re)handle the wrapped response object. 
** Use to change the processing flow. 
const class ReProcessErr : Err {
	
	** I'm not proud of this but some response objs just aren't const (e.g. Pillow PageMeta)
	** And as far as BedSheet is concerned - it *will* be processed in the same thread.
	** I don't want to chance using LocalRefs, for if it does transcend threads (by other means),
	** I won't be able to re-claim it!
	private const Unsafe responseObjRef

	** The response object
	Obj responseObj() {
		responseObjRef.val
	}
	
	** Make a 'ReProcessErr' passing in a response obj to be processed. 
	new make(Obj responseObj, Err? cause := null) : super(msg, cause) {
		this.responseObjRef = Unsafe(responseObj)
	}
}

** Throw at any point to (re)process / (re)handle the 'HttpStatus'. 
const class HttpStatusErr : ReProcessErr {
	new make(Int statusCode, Str statusMsg := WebRes.statusMsg[statusCode], Err? cause := null) : super(HttpStatus(statusCode, statusMsg), cause) { }
}

** Throw by the routing mechanism when converting uri segments to method params 
** 
** Extends `HttpStatusErr` so, by default, they cause a 404.
internal const class ValueEncodingErr : BedSheetErr {
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