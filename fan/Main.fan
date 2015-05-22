using util::AbstractMain
using util::Arg
using util::Opt

** Runs a BedSheet web application (Bed App) from the command line.
** 
** pre>
**   C:\> fan afBedSheet [-env <env>] [-proxy] [-noTransDeps] <appModule> <port>
** <pre
** 
** Where:
**   table:
** 
**   Option        Description
**   ------------- ----------------------------------------------------------------
**   env:          (optional) The environment to start BedSheet in -> dev|test|prod
**   proxy:        (optional) Starts a dev proxy on <port> and launches the real web app on (<port> + 1)
**   noTransDeps:  (optional) Do not load transitive dependencies.
**   appModule:    The qname of the AppModule or pod which configures the BedSheet web app
**   port:         The HTTP port to run the Bed App on
** 
** Example:
** 
**   C:\> fan afBedSheet -env DEV -proxy acme::AppModule 8069
** 
class Main : AbstractMain {

	@Opt { help="Starts a dev proxy on <port> and launches the real web app on (<port> + 1)" }
	private Bool proxy

	@Opt { help="Do not load transitive dependencies." }
	private Bool noTransDeps

	@Opt { help="The environment to start BedSheet in -> dev|test|prod" }
	private Str? env

	@Arg { help="The qname of the AppModule or pod which configures the BedSheet web app" }
	private Str? appModule
	
	// I could make this an @Opt but then it'd break backwards dependency and I'd have to update all
	// the docs - meh!
	@Arg { help="The HTTP port to run the Bed App on" } 
	private Int port

	** Run baby, run!
	@NoDoc
	override Int run() {
		BedSheetBuilder(appModule, !noTransDeps).startWisp(port, proxy, env)
	}
}
