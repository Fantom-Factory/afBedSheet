using util::AbstractMain
using util::Arg
using util::Opt
using wisp::WispService

class Main : AbstractMain {
	
	@Arg { help="The qname of the AppModule or pod which configures the BedSheet web app" }
	private Str? appModule
	
	@Arg { help="The HTTP port to run the app on" } 
	private Int port

	override Int run() {
		mod 	:= BedSheetWebMod(appModule)
		willow 	:= WispService { it.port=this.port; it.root=mod }
		runServices([willow])
		return 0
	}

}
