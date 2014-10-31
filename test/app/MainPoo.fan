using concurrent
using wisp
using webmod
using afIoc
//using afBedSheet

internal
class MainPoo {	
	Void main() {
		mod := RouteMod { it.routes = [
			"poo" : BedSheetWebMod(TinyBedAppModule#.qname, 8069)
		]}
		
		WispService { it.port=8069; it.root=mod }.install.start

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