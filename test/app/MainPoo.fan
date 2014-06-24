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

internal
class TinyBedAppModule {
	@Contribute { serviceType=Routes# }
	static Void contributeRoutes(OrderedConfig conf) {
		conf.add(Route(`/***`, Text.fromPlain("Hello Mum!")))
	}	
}