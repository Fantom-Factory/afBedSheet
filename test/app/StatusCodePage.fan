
internal const class StatusCodePage {
	
	Obj statusCode(Int httpStatusCode) {
		throw HttpStatusErr(httpStatusCode, "Ooops!")
	}
	
}
