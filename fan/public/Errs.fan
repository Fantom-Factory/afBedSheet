
** As thrown by BedSheet
const class BedSheetErr : Err {
	new make(Str msg := "", Err? cause := null) : super(msg, cause) {}
}
