using util::Opt

@NoDoc
class MainProxied : Main {

	@Opt { help="[internal] Starts a thread that periodically pings the proxy to stay alive" }
	private Bool pingProxy

	@Opt { help="[internal] The port the proxy runs under" }
	private Int? pingProxyPort
	
	override Str:Obj? options() {
		options	:= super.options
		options["pingProxy"] 		= pingProxy
		options["pingProxyPort"] 	= pingProxyPort ?: -1		
		return options
	}
}
