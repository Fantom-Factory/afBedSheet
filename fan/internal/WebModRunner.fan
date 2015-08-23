using inet::IpAddr
using concurrent::Actor
using web::WebMod
using wisp::WispService

internal const class WebModRunner {

	** Run baby, run!
	Int run(WebMod webMod, Int port, IpAddr? ipAddr := null) {
		// if WISP reports "sys::IOErr java.net.SocketException: Unrecognized Windows Sockets error: 10106: create"
		// then check all your ENV vars are being passed to java.
		// see http://forum.springsource.org/showthread.php?106504-Error-running-grails-project-on-alternative-port-with-STS2-6-0&highlight=Unrecognized%20Windows%20Sockets%20error
		startWisp(WispService { it.root=webMod; it.httpPort=port; it.addr = ipAddr })
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
			bsMod := (BedSheetBootMod) wisp.root
			if (bsMod.startupErr?.cause != null)
				Env.cur.err.printLine("\nCausing Err:\n\n${bsMod.startupErr.cause.traceToStr}")
		}
	}
}
