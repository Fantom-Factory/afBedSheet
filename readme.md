# afBedSheet

A web application framework for [Fantom](http://fantom.org/) built on top of [afIoc](http://repo.status302.com/doc/afIoc/#overview) and [Wisp](http://fantom.org/doc/wisp/index.html).

BedSheet is a [Fantom](http://fantom.org/) framework for delivering web applications. Built on top of
[afIoc](https://bitbucket.org/SlimerDude/afioc) and [Wisp](http://fantom.org/doc/wisp/index.html),
BedSheet aims to be: Powerful, Flexible and Simple.

BedSheet's main concern is proving a rich mechanism for the routing and delivery of content over HTTP. The generation of
content (i.e. templating) is currently a lesser concern. That said, BedSheet integrates with
[Moustache](https://bitbucket.org/xored/mustache/) from [Xored](http://www.xored.com/) and integrating with other templating engines should only require a few of lines of code.

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
