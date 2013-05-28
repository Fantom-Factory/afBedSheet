//using afBedSheet 
//using afIoc
//
//class HelloApp {
//	static Void main(Str[] args) {
//		afBedSheet::Main().main(["afBedSheet::SimpleAppModule", "8080"])
//	}
//}
//
//class SimpleAppModule {
//	@Contribute { serviceType=Router# }
//	static Void configureRouter(OrderedConfig config) {
//		config.addUnordered(Route(`/hello`, HelloPage#hello))
//	}
//}
//
//class HelloPage {
//	TextResult hello(Str name, Int iq := 666) {
//		return TextResult.fromPlain("Hello! I'm $name and I have an IQ of $iq!")
//	}
//}
