
internal const class StatusCodePage {
	
	Obj statusCode(Int httpStatusCode) {
		Env.cur.err.printLine("EWEREWRWEREWRWWR")
		throw HttpStatusErr(httpStatusCode, "Ooops!")
	}
	
}
