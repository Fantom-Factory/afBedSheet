using concurrent::Actor
using util::AbstractMain
using util::Arg
using util::Opt
using web::WebMod
using wisp::WispService

** Call to run a 'BedSheet' web application from the command line.
** 
** pre>
**   C:\> fan afBedSheet [-env <env>] [-proxy] [-noTransDeps] <appModule> <port>
** <pre
** 
** Where:
**   env:          (optional) The environment to start BedSheet in -> dev|test|prod
**   proxy:        (optional) Starts a dev proxy and launches the real web app on (<port> + 1)
**   noTransDeps:  (optional) Do not load transitive dependencies.
**   appModule:    The qname of the AppModule or pod which configures the BedSheet web app
**   port:         The HTTP port to run the app on
class Main : AbstractMain {

	@Opt { help="Starts a proxy and launches the real web app on (<port> + 1)" }
	private Bool proxy

	@Opt { help="Do not load transitive dependencies." }
	private Bool noTransDeps

	@Opt { help="The environment to start BedSheet in -> dev|test|prod" }
	private Str? env

	@Arg { help="The qname of the AppModule or pod which configures the BedSheet web app" }
	private Str? appModule
	
	// I could make this an @Opt but then it'd break backwards dependency and I'd have to update all
	// the docs - meh!
	@Arg { help="The HTTP port to run the app on" } 
	private Int port


	** Run baby, run!
	@NoDoc	// point!
	override Int run() {
		mod 	:= (WebMod) (proxy ? ProxyMod(appModule, port, noTransDeps, env) : BedSheetWebMod(appModule, port, options))

		// if WISP reports "sys::IOErr java.net.SocketException: Unrecognized Windows Sockets error: 10106: create"
		// then check all your ENV vars are being passed to java.
		// see http://forum.springsource.org/showthread.php?106504-Error-running-grails-project-on-alternative-port-with-STS2-6-0&highlight=Unrecognized%20Windows%20Sockets%20error
		willow 	:= WispService { it.port=this.port; it.root=mod }
		return startWisp(willow)
	}

	@NoDoc
	virtual Str:Obj? options() {
		options	:= Utils.makeMap(Str#, Obj?#)
		options["afBedSheet.startProxy"] 	= proxy
		options["afBedSheet.noTransDeps"] 	= noTransDeps
		return options
	}
	
	private Int startWisp(WispService wisp) {
		Env.cur.addShutdownHook |->| { shutdownWisp(wisp) }
		wisp.install
		wisp.start
		
		// give services a chance to init themselves
		Actor.sleep(2sec)
		
		// exit if wisp didn't start
		if (!wisp.isRunning) {
			Env.cur.err.printLine("Service '${wisp.typeof}' did not start")
			Env.cur.exit(69)
		}
		
		// all good, so lets hang around for a bit...
		Actor.sleep(Duration.maxVal)
		return 0
	}
	
	private static Void shutdownWisp(WispService wisp) {
		wisp.stop
		wisp.uninstall
		
		// log the cause, 'cos Service doesn't!!
		// @see http://fantom.org/sidewalk/topic/2201
		if (wisp.root is BedSheetWebMod) {
			bsMod := (BedSheetWebMod) wisp.root
			if (bsMod.startupErr?.cause != null)
				Env.cur.err.printLine("\nCausing Err:\n\n${bsMod.startupErr.cause.traceToStr}")
		}
	}
}
