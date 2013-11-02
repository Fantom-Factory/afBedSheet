using concurrent::Actor
using util::AbstractMain
using util::Arg
using util::Opt
using web::WebMod
using wisp::WispService

** Call to start Wisp and run a BedSheet app. To run BedSheet from the command line:
** 
** pre>
**   $ fan afBedSheet [-proxy] <appModule> <port>
** <pre
** 
** Where:
**  - proxy:        (optional) Starts a dev proxy and launches the real web app on (<port> + 1)
**  - appModule:    The qname of the AppModule or pod which configures the BedSheet web app
**  - port:         The HTTP port to run the app on
class Main : AbstractMain {
	
	@Opt { help="Starts a proxy and launches the real web app on (<port> + 1)" }
	private Bool proxy

	@Opt { help="No not load transitive dependencies." }
	private Bool noTransDeps

	@Arg { help="The qname of the AppModule or pod which configures the BedSheet web app" }
	private Str? appModule
	
	// I could make this an @Opt but then it'd break backwards dependency and I'd have to update all
	// the docs - meh!
	@Arg { help="The HTTP port to run the app on" } 
	private Int port


	** Run baby, run!
	override Int run() {
		mod 	:= (WebMod) (proxy ? ProxyMod(appModule, port) : BedSheetWebMod(appModule, port ,options))

		// if WISP reports "sys::IOErr java.net.SocketException: Unrecognized Windows Sockets error: 10106: create"
		// then check all your ENV vars are being passed to java.
		// see http://forum.springsource.org/showthread.php?106504-Error-running-grails-project-on-alternative-port-with-STS2-6-0&highlight=Unrecognized%20Windows%20Sockets%20error
		willow 	:= WispService { it.port=this.port; it.root=mod }
		return startServices([willow])
	}

	@NoDoc
	virtual Str:Obj? options() {
		options	:= Utils.makeMap(Str#, Obj?#)
		options["startProxy"] 	= proxy
		options["noTransDeps"] 	= noTransDeps
		return options
	}
	
	private Int startServices(Service[] services) {
		Env.cur.addShutdownHook |->| { shutdownServices }
		services.each |Service s| { s.install }
		services.each |Service s| { s.start }
		
		// give services a chance to init themselves
		Actor.sleep(2sec)
		
		// exit if any service didn't start
		services.each |Service s| { 
			if (!s.isRunning) {
				Env.cur.err.printLine("Service '${s.typeof}' did not start")
				Env.cur.exit(69)
			}
		}
		
		// all good, so lets hang around for a bit...
		Actor.sleep(Duration.maxVal)
		return 0
	}
	
	private static Void shutdownServices() {
		Service.list.each |Service s| { s.stop }
		Service.list.each |Service s| { s.uninstall }
	}
}
