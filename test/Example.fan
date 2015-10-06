using afIoc
using afBedSheet

class HelloPage {
  Text hello(Str name, Int iq := 666) {
    return Text.fromPlain("Hello! I'm $name and I have an IQ of $iq!")
  }
}

class AppModule {
  @Contribute { serviceType=Routes# }
  static Void contributeRoutes(OrderedConfig conf) {
    conf.add(Route(`/index`, Text.fromPlain("Welcome to BedSheet!")))
    conf.add(Route(`/hello/**`, HelloPage#hello))
  }
}

class Example {
  Int main() {
    afBedSheet::Main().main([AppModule#.qname, "8069"])
  }
}
