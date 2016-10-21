using concurrent
using wisp
using afIoc
using webmod::RouteMod
//using afBedSheet

internal
class MainPoo {	
	Void main() {
		bob := BedSheetBuilder(TinyBedAppModule#.qname)
		reg := bob.build
		mod := RouteMod { it.routes = [
			"poo" : BedSheetWebMod(reg)
		]}
		
		WispService { it.httpPort=8069; it.root=mod }.install.start

		Actor.sleep(Duration.maxVal)	
	}
}

** A tiny BedSheet app that returns 'Hello Mum!' for every request.
internal
const class TinyBedAppModule {
	@Contribute { serviceType=Routes# }
	static Void contributeRoutes(Configuration conf) {
		conf.add(Route(`/***`, Text.fromPlain("Hello Mum!")))
	}	
}