# afBedSheet

BedSheet is a [Fantom](http://fantom.org/) framework for delivering web applications.

Built on top of [afIoc](http://repo.status302.com/doc/afIoc/#overview) and [Wisp](http://fantom.org/doc/wisp/index.html), 
BedSheet's main concern is proving a rich mechanism for the routing and delivery of content over HTTP.

BedSheet is inspired by Java's [Tapestry5](http://tapestry.apache.org/), Ruby's [Sinatra](http://www.sinatrarb.com/) and
Fantom's [Draft](https://bitbucket.org/afrankvt/draft).


## Install

Install `BedSheet` with the [Fantom Respository Manager](http://fantom.org/doc/docFanr/Tool.html#install):

    C:\> fanr install -r http://repo.status302.com/fanr/ afBedSheet

Or download the pod from [Status302](http://repo.status302.com/browse/afBedSheet) and copy it to `%FAN_HOME%/lib/fan/`.

To use in a Fantom project, add a dependency to its `build.fan`:

    depends = ["sys 1.0", ..., "afBedSheet 1.2+"]


## Quick Start

1). Create a file called 'Example.fan':

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
        afBedSheet::Main().main([AppModule#.qname, "8080"])
      }
    }

2). Run 'Example.fan' as a script from the command line:

    C:\> fan Example.fan -env development
    ...
    BedSheet v1.0 started up in 323ms
    
    C:\> curl http://localhost:8080/index
    Welcome to BedSheet!
    
    C:\> curl http://localhost:8080/hello/Traci/69
    Hello! I'm Traci and I have an IQ of 69!
    
    C:\> curl http://localhost:8080/hello/Luci
    Hello! I'm Luci and I have an IQ of 666!

Wow! That's awesome!


## Documentation

Full API & fandocs are available on the [status302 repository](http://repo.status302.com/doc/afBedSheet/#overview).

