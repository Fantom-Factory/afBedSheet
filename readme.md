## Overview 

`BedSheet` is a [Fantom](http://fantom.org/) framework for delivering web applications.

Built on top of [IoC](http://www.fantomfactory.org/pods/afIoc) and [Wisp](http://fantom.org/doc/wisp/index.html), BedSheet provides a rich middleware mechanism for the routing and delivery of content over HTTP.

BedSheet is inspired by Java's [Tapestry5](http://tapestry.apache.org/), Ruby's [Sinatra](http://www.sinatrarb.com/) and Fantom's [Draft](https://bitbucket.org/afrankvt/draft).

## Install 

Install `BedSheet` with the Fantom Repository Manager ( [fanr](http://fantom.org/doc/docFanr/Tool.html#install) ):

    C:\> fanr install -r http://repo.status302.com/fanr/ afBedSheet

To use in a [Fantom](http://fantom.org/) project, add a dependency to `build.fan`:

    depends = ["sys 1.0", ..., "afBedSheet 1.3+"]

## Documentation 

Full API & fandocs are available on the [Status302 repository](http://repo.status302.com/doc/afBedSheet/).

## Quick Start 

1). Create a text file called `Example.fan`:

```
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
    conf.add(Route(`/index`, Text.fromPlain("Welcome to BedSheet!")))
    conf.add(Route(`/hello/**`, HelloPage#hello))
  }
}

class Example {
  Int main() {
    afBedSheet::Main().main([AppModule#.qname, "8080"])
  }
}
```

2). Run `Example.fan` as a Fantom script from the command line:

```
C:\> fan Example.fan -env development
...
BedSheet v1.2 started up in 323ms

C:\> curl http://localhost:8080/index
Welcome to BedSheet!

C:\> curl http://localhost:8080/hello/Traci/69
Hello! I'm Traci and I have an IQ of 69!

C:\> curl http://localhost:8080/hello/Luci
Hello! I'm Luci and I have an IQ of 666!
```

Wow! That's awesome! But what just happened!?

Every `BedSheet` application has an `AppModule` that configures [IoC](http://www.fantomfactory.org/pods/afIoc) services. Here we told the [Routes](http://repo.status302.com/doc/afBedSheet/Routes.html) service to return some plain text in response to `/index` and to call the `HelloPage#hello` method for all requests that start with `/hello`. [Route](http://repo.status302.com/doc/afBedSheet/Route.html) converts URI path segments into method arguments, or in our case, to `Str name` and to an optional `Int iq`.

Route handlers are typically what we, the application developers, write. They perform logic processing and render responses. Our `HelloPage` route handler simply returns a plain [Text](http://repo.status302.com/doc/afBedSheet/Text.html) response, which `BedSheet` sends to the client via an appropriate [ResponseProcessor](http://repo.status302.com/doc/afBedSheet/ResponseProcessor.html).

## Starting BedSheet 

Every Bed App (BedSheet Application) has an `AppModule` class that defines and configures your [IoC](http://www.fantomfactory.org/pods/afIoc) services. It is an [IoC](http://www.fantomfactory.org/pods/afIoc) concept that allows you centralise your application's configuration in one place. It is the `AppModule` that defines your Bed App and is central everything it does.

To start `BedSheet` from the command line, you need to tell it where to find the `AppModule` and which port to run on:

```
C:\> fan afBedSheet -env development <fully-qualified-app-module-name> <port-number>
```

For example:

```
C:\> fan afBedSheet -env development myWebApp::AppModule 8069
```

> TIP: Should your AppModule grow too big, break logical chunks out into their own classes using the @SubModule facet.

`<fully-qualified-app-module-name>` may be replaced with just `<pod-name>` as long as your pod's `build.fan` defines the following meta:

```
meta = [
    ...
    ...
    "afIoc.module" : "<fully-qualified-app-module-name>"
]
```

This allows `BedSheet` to look up your `AppModule` from the pod. Example:

```
C:\> fan afBedSheet -env development myWebApp 8069
```

Note that `AppModule` is named so out of convention but the class may be called anything you like.

## Request Routing 

The `Routes` service maps HTTP request URIs to response objects and handler methods. It is where you would typically define how requests are handled. You configure the `Routes` service by contributing instances of [Route](http://repo.status302.com/doc/afBedSheet/Route.html). Example:

```
using afIoc
using afBedSheet

class AppModule {

    @Contribute { serviceType=Routes# }
    static Void contributeRoutes(Configuration conf) {

        conf.add(Route(`/home`,  Redirect.movedTemporarily(`/index`)))
        conf.add(Route(`/index`, IndexPage#service))
    }
}
```

[Route](http://repo.status302.com/doc/afBedSheet/Route.html) objects take a matching `glob` and a response object. A response object is any object that `BedSheet` knows how to [process](http://repo.status302.com/doc/afBedSheet/#responseObjects.html) or a `Method` to be called. If a method is given, then request URI path segments are matched to the method parameters. See [Route](http://repo.status302.com/doc/afBedSheet/Route.html) for more details.

### Draft Routes 

If you prefer the [draft](https://bitbucket.org/afrankvt/draft) style of routing, that's no problem, you can use `Draft Routes` in `BedSheet`!

Add [BedSheet Draft](http://repo.status302.com/doc/afBedSheetDraft/#overview) and [draft](https://bitbucket.org/afrankvt/draft) as dependencies in your `build.fan` and you can contribute `Draft Route` objects to the `Routes` service.

Routing lesson over.

(...you Aussies may stop giggling now.)

## Route Handling 

*Route Handler* is the name given to a method that is called by a `Route`. They process logic and generally don't pipe anything to the HTTP response stream. Instead they return a *Response Object* for further processing. For example, the [Quick Start](http://repo.status302.com/doc/afBedSheet/#quickStart.html) `HelloPage` *route handler* returns a [Text](http://repo.status302.com/doc/afBedSheet/Text.html) object.

Route handlers are usually written by the application developer, but a couple of common use-cases are bundled with `BedSheet`:

- [FileHandler](http://repo.status302.com/doc/afBedSheet/FileHandler.html): Maps request URIs to files on file system.
- [PodHandler](http://repo.status302.com/doc/afBedSheet/PodHandler.html) : Maps request URIs to pod file resources.

## Response Objects 

*Response Objects* are returned from *Route Handlers*. It is then the job of [Response Processors](http://repo.status302.com/doc/afBedSheet/ResponseProcessor.html) to process these objects, converting them into data to be sent to the client. *Response Processors* may themselves return a *Response Object*, which will be handled by another *Response Processor*.

You can define *Response Processors* and process *Response Objects* yourself; but by default, `BedSheet` handles the following:

- `Void` / `null` / `false` : Processing should fall through to the next Route match.
- `true` : No further processing is required.
- [File](http://fantom.org/doc/sys/File.html) : The file is streamed to the client.
- [HttpStatus](http://repo.status302.com/doc/afBedSheet/HttpStatus.html) : Sets the HTTP response status and renders a mini html page. (See [HTTP Status Processing](http://repo.status302.com/doc/afBedSheet/#httpStatusProcessing.html).)
- [InStream](http://fantom.org/doc/sys/InStream.html) : The `InStream` is piped to the client. The `InStream` is guarenteed to be closed.
- [MethodCall](http://repo.status302.com/doc/afBedSheet/MethodCall.html) : The method is called and the return value used for further processing.
- [Redirect](http://repo.status302.com/doc/afBedSheet/Redirect.html) : Sends a 3xx redirect response to the client.
- [Text](http://repo.status302.com/doc/afBedSheet/Text.html) : The text (be it plain, json, xml, etc...) is sent to the client with a corresponding `Content-Type`.

## Template Rendering 

Templating, or formatting text (HTML or otherwise) is left for other 3rd party libraries and is not a conern of `BedSheet`. That said, there a couple templating libraries *out there* and integrating them into `BedSheet` is relatively simple. For instance, Alien-Factory provides the following libraries:

- [Slim](http://www.fantomfactory.org/pods/afSlim) for rendering HTML,
- [Pillow](http://www.fantomfactory.org/pods/afPillow) for integrating [efanXtra](http://www.fantomfactory.org/pods/afEfanXtra) components (may be used with [Slim](http://www.fantomfactory.org/pods/afSlim)!),
- [BedSheet Efan](http://repo.status302.com/doc/afBedSheetEfan/#overview) for basic [efan (Embedded Fantom)](http://www.fantomfactory.org/pods/afEfan) integration, and
- [BedSheetMoustache](http://repo.status302.com/doc/afBedSheetMoustache/#overview) for integrating [Mustache](https://bitbucket.org/xored/mustache/) templates.

Taking [Slim](http://www.fantomfactory.org/pods/afSlim) as an example, simply inject the service in your *Route Handler* and use it to return a [Text](http://repo.status302.com/doc/afBedSheet/Text.html) object:

```
using afIoc
using afBedSheet
using afSlim

class IndexPage {
    @Inject Slim? slim

    Text render() {
        xhtml := slim.renderFromFile(`xmas.xhtml.slim`.toFile)
        return Text.fromXhtml(xhtml)
    }
}
```

## BedSheet Middleware 

When a HTTP request is received, it is passed through a pipeline of BedSheet [Middleware](http://repo.status302.com/doc/afBedSheet/Middleware.html); this is a similar to [Java Servlet Filters](http://docs.oracle.com/javaee/5/api/javax/servlet/Filter.html). If the request reaches the end of the pipeline without being processed, a 404 is returned.

Middleware bundled with `BedSheet` include:

- `Routes` : Performs the standard [request routing](http://repo.status302.com/doc/afBedSheet/#requestRouting.html)
- `RequestLog`: Generates request logs in the standard [W3C Extended Log File Format](http://www.w3.org/TR/WD-logfile.html).

You can define your own middleware to address cross cutting concerns such as authentication and authorisation. See the FantomFactory article [Basic HTTP Authentication With BedSheet](http://www.fantomfactory.org/articles/basic-http-authentication-with-bedSheet) for working examples.

## Error Processing 

When `BedSheet` catches an Err it scans through a list of contributed [ErrProcessors](http://repo.status302.com/doc/afBedSheet/ErrProcessor.html) to find one that can handle the Err. [ErrProcessors](http://repo.status302.com/doc/afBedSheet/ErrProcessor.html) take an Err and return a *Response Object* for further processing (for example, [Text](http://repo.status302.com/doc/afBedSheet/Text.html)). Or it may return `true` if the error has been completely handled and no further processing is required.

If no matching `ErrProcessor` is found then `BedSheet` displays its default Err500 page - which is extremely verbose, displays (a shed load of) debugging information and is highly customisable.

![BedSheet's Verbose Err500 Page](http://static.alienfactory.co.uk/fantom-docs/Err500.png)

The default Err page is great for development! But not so great for production - stack traces tend to scare Joe Public. So note that in a production environment (see [IocEnv](http://www.fantomfactory.org/pods/afIocEnv)) a simple HTTP status page is displayed instead.

> **ALIEN-AID:** BedSheet defaults to production mode, so set an environment variable called `ENV` with the value `development` to ensure you continue to see the BedSheet's verbose Err500 page. See this [Fantom-Factory article](http://www.fantomfactory.org/articles/dev-test-or-prod-what-is-your-machine) for more details.

To add a custom error page, contribute an [ErrProcessor](http://repo.status302.com/doc/afBedSheet/ErrProcessor.html) to [ErrProcessors](http://repo.status302.com/doc/afBedSheet/ErrProcessors.html):

```
@Contribute { serviceType=ErrProcessors# }
static Void contributeErrProcessors(MappedConfig conf) {

  conf[Err#] = conf.autobuild(MyErrHandler#)
}
```

## HTTP Status Processing 

`HttpStatus` responses are handled by [HttpStatusProcessors](http://repo.status302.com/doc/afBedSheet/HttpStatusProcessors.html) which select a contributed processor dependent on the HTTP status code. If none are found, a default catch all processor sets the HTTP status code and sends a mini html page to the client. This is the default page you see when you receive a `404 Not Found` error.

![BedSheet's 404 Status Page](http://static.alienfactory.co.uk/fantom-docs/Err404.png)

To set your own `404 Not Found` page, contribute a [HttpStatusProcessor](http://repo.status302.com/doc/afBedSheet/HttpStatusProcessor.html) to the [HttpStatusProcessors](http://repo.status302.com/doc/afBedSheet/HttpStatusProcessors.html) service for the status code 404:

```
@Contribute { serviceType=HttpStatusProcessors# }
static Void contributeHttpStatusProcessors(MappedConfig conf) {

  conf[404] = conf.autobuild(My404Handler#)
}
```

## Config Injection 

BedSheet uses [IoC Config](http://www.fantomfactory.org/pods/afIocConfig) to give injectable `@Config` values. `@Config` values are essesntially a map of Str to immutable / constant values that may be set and overriden at application start up. (Consider config values to be immutable once the app has started).

BedSheet sets the initial config values by contributing to the `FactoryDefaults` service. An application may then override these values by contibuting to the `ApplicationDefaults` service.

```
@Contribute { serviceType=ApplicationDefaults# }
static Void contributeApplicationDefaults(MappedConfig conf) {
    ...
    conf["afBedSheet.errPrinter.noOfStackFrames"] = 100
    ...
}
```

All BedSheet config keys are listed in [BedSheetConfigIds](http://repo.status302.com/doc/afBedSheet/BedSheetConfigIds.html) meaning the above can be more safely rewriten as:

```
conf[BedSheetConfigIds.noOfStackFrames] = 100
```

To inject config values in your services, use the `@Config` facet with conjunction with [IoC](http://www.fantomfactory.org/pods/afIoc)'s `@Inject`:

```
@Inject @Config { id="afBedSheet.errPrinter.noOfStackFrames" }
Int noOfStackFrames
```

The config mechanism is not just for BedSheet, you can use it too when creating 3rd Party libraries! Contributing initial values to `FactoryDefaults` gives users of your library an easy way to override your values.

## Request Logging 

BedSheet can generate standard HTTP request logs in the [W3C Extended Log File Format](http://www.w3.org/TR/WD-logfile.html).

To enable, just configure the directory where the logs should be written and (optionally) set the log filename, or filename pattern for log rotation:

```
@Contribute { serviceType=ApplicationDefaults# }
static Void contributeApplicationDefaults(Configuration conf) {

    conf[BedSheetConfigIds.requestLogDir]             = `/my/log/dir/`
    conf[BedSheetConfigIds.requestLogFilenamePattern] = "bedSheet-{YYYY-MM}.log"
}
```

Ensure the log dir ends in a trailing /slash/.

The fields writen to the logs may be set by configuring `BedSheetConfigIds.requestLogFields`, but default to looking like:

```
2013-02-22 13:13:13 127.0.0.1 - GET /doc - 200 222 "Mozilla/5.0 (Windows; U; Windows NT 6.1; en-US) etc" "http://localhost/index"

```

## Development Proxy 

Never (manually) restart your app again!

Use the `-proxy` option when starting BedSheet to create a Development Proxy and your app will auto re-start when a pod is updated:

```
C:\> fan afBedSheet -proxy <mypod> <port>
```

The proxy sits on `<port>` and starts your real app on `<port>+1`, forwarding all requests to it.

```
Client <--> Proxy (port) <--> Web App (port+1)
```

A problem other (Fantom) web development proxies suffer from is that, when the proxy dies, your real web app is left hanging around; requiring you to manually kill it.

```
Client <-->   ????????   <--> Web App (port+1)
```

BedSheet applications go a step further and, should it be started in proxy mode, it pings the proxy every second to stay alive. Should the proxy not respond, the web app kills itself.

See [proxyPingInterval](http://repo.status302.com/doc/afBedSheet/BedSheetConfigIds#proxyPingInterval.html) for more details.

## Gzip 

By default, BedSheet compresses HTTP responses with gzip where it can.(1) But it doesn't do this willy nilly, oh no! There are many hurdles to overcome...

#### Disable All 

Gzip, although enabled by default, can be disabled for the entire web app by setting the following config property:

    config[BedSheetConfigIds.gzipDisabled] = true

#### Disable per Response 

Gzip can be disabled on a per request / response basis by calling the following:

    httpResponse.disableGzip()

#### Gzip'able Mime Types 

Not everything should be gzipped. For example, text files gzip very well and yield high compression rates. JPG images on the other hand, because they're already compressed, don't gzip well and can end up bigger than the original! For this reason you must contribute to the [GzipCompressible](http://repo.status302.com/doc/afBedSheet/GzipCompressible.html) service to enable gzip for specified [Mime Types](http://fantom.org/doc/sys/MimeType.html):

    config["text/funky"] = true

(Note: The GzipCompressible contrib type is actually [sys::MimeType](http://fantom.org/doc/sys/MimeType.html) - [IoC](http://www.fantomfactory.org/pods/afIoc) kindly coerces the `Str` to `MimeType` for us.)

By default BedSheet will compress plain text, css, html, javascript, xml, json and other text responses.

#### Gzip only when asked 

Guaranteed that someone, somewhere is still using Internet Explorer 3.0 and they can't handle gzipped content. As such, and as per [RFC 2616 HTTP1.1 Sec14.3](http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.3), we only gzip the response if the client actually *asked* for it!

#### Min content threshold 

Gzip is great when compressing large files, but if you've only got a few bytes to squash... the compressed version is going to be bigger, which kinda defeats the point of using gzip in the first place! For that reason the response data must reach a minimum size / threshold before it gets gzipped.

See `GzipOutStream` and [gzipThreshold](http://repo.status302.com/doc/afBedSheet/BedSheetConfigIds#gzipThreshold.html) for more details.

#### Phew! Made it! 

If (and only if!) your request passed all the tests above, will it then be lovingly gzipped and sent to the client.

- (1) [http://betterexplained.com/articles/how-to-optimize-your-site-with-gzip-compression/](http://betterexplained.com/articles/how-to-optimize-your-site-with-gzip-compression/)

## Buffered Response 

By default, BedSheet attempts to set the `Content-Length` HTTP response header.(2) It does this by buffering `HttpResponse.out`. When the stream is closed, it writes the `Content-Length` and pipes the buffer to the real HTTP response.

Response buffering can be disabled on a per HTTP response basis.

A threshold can be set, whereby if the buffer exeeds that value, all content is streamed directly to the client.

See `BufferedOutStream` and [responseBufferThreshold](http://repo.status302.com/doc/afBedSheet/BedSheetConfigIds#responseBufferThreshold.html) for more details.

- (2) [http://stackoverflow.com/questions/2419281/content-length-header-versus-chunked-encoding](http://stackoverflow.com/questions/2419281/content-length-header-versus-chunked-encoding)

## Tips 

All route handlers and processors are built by [IoC](http://www.fantomfactory.org/pods/afIoc) so feel free to `@Inject` DAOs and other services.

BedSheet itself is built with [IoC](http://www.fantomfactory.org/pods/afIoc) so look at the [BedSheet Source](https://bitbucket.org/AlienFactory/afbedsheet/src) for [IoC](http://www.fantomfactory.org/pods/afIoc) examples.

Even if your route handlers aren't services, if they're `const` classes, they're cached by BedSheet and reused on every request.

## Go Live with Heroku 

In a hurry to go live? Use [Heroku](http://www.heroku.com/)!

[Heroku](http://www.heroku.com/) and the [heroku-fantom-buildpack](https://bitbucket.org/AlienFactory/heroku-buildpack-fantom) makes it ridiculously to deploy your web app to a live server. Just check in your code and Heroku will build your web app from source and deploy it to a live environment!

To have Heroku run your BedSheet web app you have 2 options:

1) Create a Heroku text file called `Procfile` at the same level as your `build.fan` with the following line:

```
web: fan afBedSheet <fully-qualified-app-module-name> $PORT
```

substituting `<fully-qualified-app-module-name>` with, err, your fully qualified app module name! Example, `MyPod::AppModule`. Type `$PORT` verbatim, as it is.

2) Create a Main class in your app:

```
using util

class Main : AbstractMain {

  @Arg { help="The HTTP port to run the app on" }
  private Int port

  override Int run() {
    return afBedSheet::Main().main("<fully-qualified-app-module-name> $port".split)
  }
}
```

Main classes have the advantage of being easy to run from an IDE or cmd line.

See [heroku-fantom-buildpack](https://bitbucket.org/AlienFactory/heroku-buildpack-fantom) for more details.

