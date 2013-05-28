
** As thrown by Config
internal const class ConfigErr : Err {
	new make(Str msg := "", Err? cause := null) : super(msg, cause) {}
}