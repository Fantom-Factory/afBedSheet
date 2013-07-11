
** As thrown by BedSheet
const class BedSheetErr : Err {
	new make(Str msg := "", Err? cause := null) : super(msg, cause) {}
}

** Throw by the routing mechanism when converting uri segments to method params 
** 
** Extends `HttpStatusErr` so, by default, they cause a 404.
internal const class ValueEncodingErr : HttpStatusErr {
	new make(Str msg := "", Err? cause := null) : super(404, msg, cause) {}
}
