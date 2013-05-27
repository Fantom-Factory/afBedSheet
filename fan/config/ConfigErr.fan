
** As thrown by Config
const class ConfigErr : Err {
	new make(Str msg := "", Err? cause := null) : super(msg, cause) {}
}