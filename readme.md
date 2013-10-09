# afBedSheet

BedSheet is a [Fantom](http://fantom.org/) framework for delivering web applications.

Built on top of [afIoc](http://repo.status302.com/doc/afIoc/#overview) and [Wisp](http://fantom.org/doc/wisp/index.html), 
BedSheet's main concern is proving a rich mechanism for the routing and delivery of content over HTTP.

BedSheet is inspired by Java's [Tapestry5](http://tapestry.apache.org/), Ruby's [Sinatra](http://www.sinatrarb.com/) and
Fantom's [Draft](https://bitbucket.org/afrankvt/draft).

## Quick Start

Write your fantom web app:

    using afBedSheet
    using afIoc

    class AppModule {
      @Contribute
      static Void contributeRoutes(OrderedConfig conf) {
        conf.add(Route(`/hello/**`, HelloPage#hello))
      }
    }

    class HelloPage {
      Text hello(Str name, Int iq := 666) {
        return Text.fromPlain("Hello! I'm $name and I have an IQ of $iq!")
      }
    }

Run it:

    $ fan afBedSheet <mypod>::AppModule 8080
    ...
    BedSheet v1.0 started up in 323ms

    $ curl http://localhost:8080/hello/Traci/69
    Hello! I'm Traci and I have an IQ of 69!

    $ curl http://localhost:8080/hello/Luci
    Hello! I'm Luci and I have an IQ of 666!



## Documentation

Full API & fandocs are available on the [status302 repository](http://repo.status302.com/doc/afBedSheet/#overview).



## Install

Download from [status302](http://repo.status302.com/browse/afBedSheet).

Or install via fanr:

    $ fanr install -r http://repo.status302.com/fanr/ afBedSheet

To use in a project, add a dependency in your `build.fan`:

    depends = ["sys 1.0", ..., "afBedSheet 1.0+"]
