using afIoc
using afBedSheet

class HelloPage {
  Text hello(Str name, Int iq := 666) {
    return Text.fromPlain("Hello! I'm $name and I have an IQ of $iq!")
  }
}

class AppModule {
  @Contribute { serviceType=Routes# }
  static Void contributeRoutes(Configuration conf) {
    conf.add(Route(`/index`, Text.fromHtml("<html><body>Welcome to BedSheet!</body></html>")))
    conf.add(Route(`/hello/**`, HelloPage#hello))
  }
}

class Example {
  Int main() {
    afBedSheet::Main().main([AppModule#.qname, "8080"])
  }
}