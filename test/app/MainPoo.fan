using concurrent
using wisp
using webmod
using afIoc
//using afBedSheet

internal
class MainPoo {	
	Void main() {
		bob := BedSheetBuilder(TinyBedAppModule#.qname)
		reg := bob.build.startup
		mod := RouteMod { it.routes = [
			"poo" : BedSheetWebMod(reg)
		]}
		
		WispService { it.httpPort=8069; it.root=mod }.install.start

		Actor.sleep(Duration.maxVal)	
	}
}

** A tiny BedSheet app that returns 'Hello Mum!' for every request.
internal
class TinyBedAppModule {
	@Contribute { serviceType=Routes# }
	static Void contributeRoutes(Configuration conf) {
		conf.add(Route(`/***`, Text.fromPlain("Hello Mum!")))
	}	
}