using util::AbstractMain
using util::Arg
using util::Opt
using web::WebMod
using wisp::WispService

class Main : AbstractMain {
	
	@Opt { help="Go go go Gadget!" } 
	private Bool devMode

	@Arg { help="The qname of the AppModule or pod which configures the BedSheet web app" }
	private Str? appModule
	
	@Arg { help="The HTTP port to run the app on" } 
	private Int port

	override Int run() {
		mod 	:= (WebMod) (devMode ? DevProxyMod(appModule, port) : BedSheetWebMod(appModule))
//		mod 	:= (WebMod) BedSheetWebMod(appModule)

		// if WISP reports "sys::IOErr java.net.SocketException: Unrecognized Windows Sockets error: 10106: create"
		// then check all your ENV vars are being passed to java.
		// see http://forum.springsource.org/showthread.php?106504-Error-running-grails-project-on-alternative-port-with-STS2-6-0&highlight=Unrecognized%20Windows%20Sockets%20error
		willow 	:= WispService { it.port=this.port; it.root=mod }
		runServices([willow])
			
		return 0
	}

}
