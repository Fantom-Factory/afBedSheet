#BedSheet v1.4.12
---
[![Written in: Fantom](http://img.shields.io/badge/written%20in-Fantom-lightgray.svg)](http://fantom.org/)
[![pod: v1.4.12](http://img.shields.io/badge/pod-v1.4.12-yellow.svg)](http://www.fantomfactory.org/pods/afBedSheet)
![Licence: MIT](http://img.shields.io/badge/licence-MIT-blue.svg)

## Overview

BedSheet is a platform for delivering web applications written in [Fantom](http://fantom.org/).

Built on top of [IoC](http://pods.fantomfactory.org/pods/afIoc) and [Wisp](http://fantom.org/doc/wisp/index.html), BedSheet provides a rich middleware mechanism for the routing and delivery of content over HTTP.

BedSheet is inspired by Java's [Tapestry5](http://tapestry.apache.org/), Ruby's [Sinatra](http://www.sinatrarb.com/) and Fantom's [Draft](https://bitbucket.org/afrankvt/draft).

## Install

Install `BedSheet` with the Fantom Repository Manager ( [fanr](http://fantom.org/doc/docFanr/Tool.html#install) ):

    C:\> fanr install -r http://repo.status302.com/fanr/ afBedSheet

To use in a [Fantom](http://fantom.org/) project, add a dependency to `build.fan`:

    depends = ["sys 1.0", ..., "afBedSheet 1.4"]

## Documentation

Full API & fandocs are available on the [Fantom Pod Repository](http://pods.fantomfactory.org/pods/afBedSheet/).

## Quick Start

1. Create a text file called `Example.fan`:

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
                BedSheetBuilder(AppModule#.qname).startWisp(8080)
            }
        }


2. Run `Example.fan` as a Fantom script from the command line:

        C:\> fan Example.fan -env development
        
        [info] [afBedSheet] Found mod 'Example_0::AppModule'
        [info] [afIoc] Adding module definitions from pod 'Example_0'
        [info] [afIoc] Adding module definition for Example_0::AppModule
        [info] [afIoc] Adding module definition for afBedSheet::BedSheetModule
        [info] [afIoc] Adding module definition for afIocConfig::ConfigModule
        [info] [afIoc] Adding module definition for afIocEnv::IocEnvModule
        [info] [afBedSheet] Starting Bed App 'Example_0::AppModule' on port 8080
        [info] [web] WispService started on port 8080
        
        40 IoC Services:
          10 Builtin
          26 Defined
           0 Proxied
           4 Created
        
        65.00% of services are unrealised (26/40)
           ___    __                 _____        _
          / _ |  / /_____  _____    / ___/__  ___/ /_________  __ __
         / _  | / // / -_|/ _  /===/ __// _ \/ _/ __/ _  / __|/ // /
        /_/ |_|/_//_/\__|/_//_/   /_/   \_,_/__/\__/____/_/   \_, /
                   Alien-Factory BedSheet v1.4.8, IoC v2.0.6 /___/
        
        IoC Registry built in 210ms and started up in 20ms
        
        Bed App 'Example_0' listening on http://localhost:8080/


3. Visit `localhost` to hit the web application:

        C:\> curl http://localhost:8080/index
        <html><body>Welcome to BedSheet!</body></html>
        
        C:\> curl http://localhost:8080/hello/Traci/69
        Hello! I'm Traci and I have an IQ of 69!
        
        C:\> curl http://localhost:8080/hello/Luci
        Hello! I'm Luci and I have an IQ of 666!



Wow! That's awesome! But what just happened!?

Every BedSheet application has an `AppModule` that configures [IoC](http://pods.fantomfactory.org/pods/afIoc) services. Here we told the [Routes](http://pods.fantomfactory.org/pods/afBedSheet/api/Routes) service to return some plain text in response to `/index` and to call the `HelloPage#hello` method for all requests that start with `/hello`. [Route](http://pods.fantomfactory.org/pods/afBedSheet/api/Route) converts URL path segments into method arguments, or in our case, to `Str name` and to an optional `Int iq`.

Route handlers are typically what we, the application developers, write. They perform logic processing and render responses. Our `HelloPage` route handler simply returns a plain [Text](http://pods.fantomfactory.org/pods/afBedSheet/api/Text) response, which BedSheet sends to the client via an appropriate [ResponseProcessor](http://pods.fantomfactory.org/pods/afBedSheet/api/ResponseProcessor).

## Starting BedSheet

To start BedSheet from the command line, you need to tell it where to find an `AppModule` and the port to run on:

```
C:\> fan afBedSheet -env development <qualified-app-module-name> <port-number>
```

For example:

```
C:\> fan afBedSheet -env development myWebApp::AppModule 8069
```

Every Bed App (BedSheet Application) has an `AppModule` class that defines and configures your [IoC](http://pods.fantomfactory.org/pods/afIoc) services. It is an [IoC](http://pods.fantomfactory.org/pods/afIoc) concept that allows you centralise your application's configuration in one place. It is the `AppModule` that defines your Bed App and is central everything it does.

`<qualified-app-module-name>` may be replaced with just `<pod-name>` as long as your pod's `build.fan` defines the following meta:

```
meta = [
    ...
    ...
    "afIoc.module" : "<qualified-app-module-name>"
]
```

This allows BedSheet to look up your `AppModule` from the pod. Example:

```
C:\> fan afBedSheet -env development myWebApp 8069
```

Note that `AppModule` is named so out of convention but the class may be called anything you like.

## Request Routing

The `Routes` service maps HTTP request URLs to response objects and handler methods. It is where you would typically define how requests are handled. You configure the `Routes` service by contributing instances of [Route](http://pods.fantomfactory.org/pods/afBedSheet/api/Route). Example:

```
using afIoc
using afBedSheet

class AppModule {

    @Contribute { serviceType=Routes# }
    static Void contributeRoutes(Configuration conf) {

        conf.add(Route(`/home`,  Redirect.movedTemporarily(`/index`)))
        conf.add(Route(`/index`, IndexPage#service))
        conf.add(Route(`/work`,  WorkPage#service, "POST"))
    }
}
```

[Route](http://pods.fantomfactory.org/pods/afBedSheet/api/Route) objects take a matching `glob` and a response object. A response object is any object that BedSheet knows how to [process](#responseObjects) or a `Method` to be called. If a method is given, then request URL path segments are matched to the method parameters. See [Route](http://pods.fantomfactory.org/pods/afBedSheet/api/Route) for more details.

Routing lesson over.

(...you Aussies may stop giggling now.)

## Route Handling

*Route Handler* is the name given to a class or method that is processed by a `Route`. They process logic and generally don't pipe anything to the HTTP response stream. Instead they return a *Response Object* for further processing. For example, the [Quick Start](#quickStart) `HelloPage` *route handler* returns a [Text](http://pods.fantomfactory.org/pods/afBedSheet/api/Text) *response object*.

Route handlers are written by the application developer, but a couple of common use-cases are bundled with BedSheet:

- [FileHandler](http://pods.fantomfactory.org/pods/afBedSheet/api/FileHandler): Maps request URLs to files on the file system.
- [PodHandler](http://pods.fantomfactory.org/pods/afBedSheet/api/PodHandler) : Maps request URLs to pod file resources.

See the [FileHandler](http://pods.fantomfactory.org/pods/afBedSheet/api/FileHandler) documentation for examples on how to serve up static files.

See the [PodHandler](http://pods.fantomfactory.org/pods/afBedSheet/api/PodHandler) documentation for examples on how to serve up static pod files, including Fantom generated Javascript.

(Note that, as of BedSheet 1.4.10, `FileHandler` and `PodHandler` are actually processed by Asset Middleware and not Routes.)

## Response Objects

*Response Objects* are returned from *Route Handlers*. It is then the job of [Response Processors](http://pods.fantomfactory.org/pods/afBedSheet/api/ResponseProcessor) to process these objects, converting them into data to be sent to the client. *Response Processors* may themselves return *Response Objects*, which will be handled by another *Response Processor*.

You can define *Response Processors* and process *Response Objects* yourself; but by default, BedSheet handles the following:

- `Void` / `null` / `false` : Processing should fall through to the next Route match.
- `true` : No further processing is required.
- [Asset](http://pods.fantomfactory.org/pods/afBedSheet/api/Asset) : The asset is piped to the client.
- [ClientAsset](http://pods.fantomfactory.org/pods/afBedSheet/api/ClientAsset) : Caching and identity headers are set and the asset piped to the client.
- [Err](http://fantom.org/doc/sys/Err.html) : An appropriate response object is selected from contributed Err responses. (See [Error Processing](#errorProcessing).)
- [Field](http://fantom.org/doc/sys/Field.html) : The field value is returned for further processing. (*)
- [File](http://fantom.org/doc/sys/File.html) : The file is piped to the client.
- [Func](http://fantom.org/doc/sys/Func.html) : The function is called, using IoC to inject the parameters. The return value is treated as a new reposonse object for further processing.
- [HttpStatus](http://pods.fantomfactory.org/pods/afBedSheet/api/HttpStatus) : An appropriate response object is selected from contributed HTTP status responses. (See [HTTP Status Processing](#httpStatusProcessing).)
- [InStream](http://fantom.org/doc/sys/InStream.html) : The `InStream` is piped to the client. The `InStream` is guaranteed to be closed.
- [MethodCall](http://pods.fantomfactory.org/pods/afBedSheet/api/MethodCall) : The method is called and the return value used for further processing. (*)
- [Redirect](http://pods.fantomfactory.org/pods/afBedSheet/api/Redirect) : Sends a 3xx redirect response to the client.
- [Text](http://pods.fantomfactory.org/pods/afBedSheet/api/Text) : The text (be it plain, json, xml, etc...) is sent to the client with a corresponding `Content-Type`.

Because of the nature of response object processing it is possible, nay normal, to *chain* multiple response objects together. Example:

1. If a Route returns or throws an `Err`,
2. `ErrProcessor` looks up its responses and returns a `Func`,
3. `FuncProcessor` calls a handler method which returns a `Text`,
4. `TextProcessor` serves content to the client and returns `true`.

Note that response object processing is extensible, just contribute your own [Response Processor](http://pods.fantomfactory.org/pods/afBedSheet/api/ResponseProcessor).

(*) If the slot is not static, then if the parent class:

- is a service then it is retrieved from IoC,
- is `const` then a single instance is created, used, and cached for future use,
- is not `const` then an instance is created, used, and discarded.

## Template Rendering

Templating, or formatting text (HTML or otherwise) is left for other 3rd party libraries and is not a conern of BedSheet. That said, there a couple templating libraries *out there* and integrating them into BedSheet is relatively simple. For instance, Alien-Factory provides the following libraries:

- [efan](http://pods.fantomfactory.org/pods/afEfan) for basic templating,
- [Slim](http://pods.fantomfactory.org/pods/afSlim) for concise HTML templating, and
- [Pillow](http://pods.fantomfactory.org/pods/afPillow) for integrating [efanXtra](http://pods.fantomfactory.org/pods/afEfanXtra) components (may be used with [Slim](http://pods.fantomfactory.org/pods/afSlim)!)

Taking [Slim](http://pods.fantomfactory.org/pods/afSlim) as an example, simply inject the Slim service into your *Route Handler* and use it to return a `Text` response object:

```
using afIoc::Inject
using afBedSheet::Text
using afSlim::Slim

class IndexPage {
    @Inject Slim? slim

    Text render() {
        html := slim.renderFromFile(`xmas.html.slim`.toFile)
        return Text.fromHtml(html)
    }
}
```

## BedSheet Middleware

When a HTTP request is received, it is passed through a pipeline of BedSheet [Middleware](http://pods.fantomfactory.org/pods/afBedSheet/api/Middleware); this is a similar to [Java Servlet Filters](http://docs.oracle.com/javaee/5/api/javax/servlet/Filter.html). If the request reaches the end of the pipeline without being processed, a 404 is returned.

Middleware bundled with BedSheet include:

- `RequestLog`: Generates request logs in the standard [W3C Extended Log File Format](http://www.w3.org/TR/WD-logfile.html).
- `Routes` : Performs the standard [request routing](#requestRouting)

You can define your own middleware to address cross cutting concerns such as authentication and authorisation. See the FantomFactory article [Basic HTTP Authentication With BedSheet](http://www.fantomfactory.org/articles/basic-http-authentication-with-bedSheet) for working examples.

## Error Processing

When BedSheet catches an Err it scans through a list of contributed response objects to find one that can handle the Err. If no matching response object is found then the *default err response object* is used. This default response object displays BedSheet's extremely verbose Error 500 page. It displays (a shed load of) debugging information and is highly customisable:

![BedSheet's Verbose Err500 Page](http://pods.fantomfactory.org/pods/afBedSheet/doc/err500.png)

The BedSheet Err page is great for development, but not so great for production - stack traces tend to scare Joe Public! So note that in a production environment (see [IocEnv](http://pods.fantomfactory.org/pods/afIocEnv)) a simple HTTP status page is displayed instead.

> **ALIEN-AID:** BedSheet defaults to production mode, so to see the verbose error page you must switch to development mode. The easiest way to do this is to set an environment variable called `ENV` with the value `development`. See [IocEnv](http://pods.fantomfactory.org/pods/afIocEnv) details.

To handle a specific Err, contribute a response object to `ErrResponses`:

```
@Contribute { serviceType=ErrResponses# }
static Void contributeErrResponses(Configuration config) {
    config[ArgErr#] = MethodCall(MyErrHandler#process).toImmutableFunc
}
```

Note that in the above example, `ArgErr` and all subclasses of `ArgErr` will be processed by `MyErrHandler.process()`. A contribute for just `Err` will act as a capture all and be used should a more precise match not be found. You could also replace the default err response object:

```
@Contribute { serviceType=ApplicationDefaults# }
static Void contributeApplicationDefaults(Configuration config) {
    config[BedSheetConfigIds.defaultErrResponse] = Text.fromHtml("<html><b>Oops!</b></html>")
}
```

`Err` objects are stored in the `HttpRequest.stash` map and may be retrieved by handlers with the following:

    err := (Err) httpRequest.stash["afBedSheet.err"]

## HTTP Status Processing

`HttpStatus` objects are handled by a [ResponseProcessor](http://pods.fantomfactory.org/pods/afBedSheet/api/ResponseProcessor) that selects a contributed response object that corresponds to the HTTP status code. If no specific response object is found then the *default http status response object* is used. This default response object displays BedSheet's HTTP Status Code page. This is what you see when you receive a `404 Not Found` error.

![BedSheet's 404 Status Page](http://pods.fantomfactory.org/pods/afBedSheet/doc/err404.png)

To set your own `404 Not Found` page contribute a response object to [HttpStatusResponses](http://pods.fantomfactory.org/pods/afBedSheet/api/HttpStatusResponses) service with the status code `404`:

```
@Contribute { serviceType=HttpStatusResponses# }
static Void contribute404Response(Configuration config) {
    config[404] = MethodCall(Error404Page#process).toImmutableFunc
}
```

In the above example, all 404 status codes will be processed by `Error404Page.process()`.

To replace *all* status code responses, replace the default HTTP status response object:

```
@Contribute { serviceType=ApplicationDefaults# }
static Void contributeApplicationDefaults(Configuration config) {
    config[BedSheetConfigIds.defaultHttpStatusResponse] = Text.fromHtml("<html>Error</html>")
}
```

`HttpStatus` objects are stored in the `HttpRequest.stash` map and may be retrieved by handlers with the following:

    httpStatus := (HttpStatus) httpRequest.stash["afBedSheet.httpStatus"]

## Config Injection

BedSheet uses [IoC Config](http://pods.fantomfactory.org/pods/afIocConfig) to give injectable `@Config` values. `@Config` values are essentially a map of Str to immutable / constant values that may be set and overriden at application start up. (Consider config values to be immutable once the app has started).

BedSheet sets the initial config values by contributing to the `FactoryDefaults` service. An application may then override these values by contributing to the `ApplicationDefaults` service.

```
@Contribute { serviceType=ApplicationDefaults# }
static Void contributeApplicationDefaults(Configuration conf) {
    ...
    conf["afBedSheet.errPrinter.noOfStackFrames"] = 100
    ...
}
```

All BedSheet config keys are listed in [BedSheetConfigIds](http://pods.fantomfactory.org/pods/afBedSheet/api/BedSheetConfigIds) meaning the above can be more safely rewriten as:

```
conf[BedSheetConfigIds.noOfStackFrames] = 100
```

To inject config values in your services, use the `@Config` facet with conjunction with [IoC](http://pods.fantomfactory.org/pods/afIoc)'s `@Inject`:

```
@Inject @Config { id="afBedSheet.errPrinter.noOfStackFrames" }
Int noOfStackFrames
```

The config mechanism is not just for BedSheet, you can use it too when creating 3rd Party libraries! Contributing initial values to `FactoryDefaults` gives users of your library an easy way to override your values.

## RESTful Services

BedSheet can be used to create RESTful applications. The general approach is to use `Routes` to define the URLs and HTTP methods that your app responds to.

For example, for a `POST` method:

```
class RestAppModule {
    @Contribute { serviceType=Routes# }
    static Void contributeRoutes(Configuration conf) {
        conf.add(Route(`/restAPI/*`, RestService#post, "POST"))
    }
}
```

The routes then delegate to methods on a `RouteHandler` service:

```
using afIoc
using afBedSheet

class RestService {
    @Inject HttpRequest  httpRequest
    @Inject HttpResponse httpResponse

    new make(|This| in) { in(this) }

    Text post(Int id) {
        // use the request body to get submitted data as...

        // a [Str:Str] form map or
        form := httpRequest.body.form

        // as JSON objects
        json := httpRequest.body.jsonObj

        // return a different status code, e.g. 201 - Created
        httpResponse.statusCode = 201

        // return plain text or JSON objects to the client
        return Text.fromPlainText("OK")
    }
}
```

## File Uploading

File uploading can be pretty horrendous in other languages, but here in Fantom land it's pretty easy.

First create your HTML. Here's a form snippet:

```
<form action="/uploadFile" method="POST" enctype="multipart/form-data">
    <input name="theFile" type="file" />
    <input type="submit" value="Upload File" />
</form>
```

A `Route` should then service the `/uploadFile` URL:

```
class RestAppModule {
    @Contribute { serviceType=Routes# }
    static Void contributeRoutes(Configuration conf) {
        conf.add(Route(`/uploadFile`, UploadService#uploadFile, "POST"))
    }
}
```

The `UploadService` uses `HttpRequest.parseMultiPartForm()` to gain access to the uploaded data and save it as a file:

```
using afIoc
using afBedSheet

class UploadService {
    @Inject HttpRequest? httpRequest

    Text uploadFile() {
        httpRequest.parseMultiPartForm |Str inputName, InStream in, Str:Str headers| {
            // this closure is called for each input in the form
            if (inputName == "theFile") {
                quoted   := headers["Content-Disposition"].split(';').find { it.startsWith("filename") }.split('=')[1]
                filename := WebUtil.fromQuotedStr(quoted)

                // save file to temp dir
                file := Env.cur.tempDir.createFile(filename)
                in.pipe(file.out)
                file.out.close
            }
        }
        return Text.fromPlain("OK")
    }
}
```

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

## Gzip

BedSheet compresses HTTP responses with gzip where it can for [HTTP optimisation](http://betterexplained.com/articles/how-to-optimize-your-site-with-gzip-compression/). Gzipping in BedSheet is highly configurable.

Gzip may be disabled for the entire web app by setting the following config property:

```
@Contribute { serviceType=ApplicationDefaults# }
static Void contributeApplicationDefaults(Configuration config) {
    config[BedSheetConfigIds.gzipDisabled] = true
}
```

Or Gzip can be disabled on a per request / response basis by calling:

```
HttpResponse.disableGzip()
```

Text files gzip very well and yield high compression rates, but not everything should be gzipped. For example, JPG images are already compressed when gzip'ed often end up larger than the original! For this reason only [Mime Types](http://fantom.org/doc/sys/MimeType.html) contributed to the [GzipCompressible](http://pods.fantomfactory.org/pods/afBedSheet/api/GzipCompressible) service will be gzipped.

Most standard compressible types are already contributed to `GzipCompressible` including html, css, javascript, json, xml and other text responses. You may contribute your own with:

```
@Contribute { serviceType=GzipCompressible# }
static Void configureGzipCompressible(Configuration config) {
    config[MimeType("text/funky")] = true
}
```

Guaranteed that someone, somewhere is still using Internet Explorer 3.0 - or some other client that can't handle gzipped content from the server. As such, and as per [RFC 2616 HTTP1.1 Sec14.3](http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.3), the response is only gzipped if the appropriate HTTP request header was set.

Gzip is great when compressing large files, but if you've only got a few bytes to squash... then the compressed version is going to be bigger than the original - which kinda defeats the point compression! For that reason the response data must reach a minimum size / threshold before it gets gzipped. See [gzipThreshold](http://pods.fantomfactory.org/pods/afBedSheet/api/BedSheetConfigIds.gzipThreshold) for more details.

## Buffered Response

If a `Content-Length` header was not supplied then BedSheet attempts to calculate it by buffering `HttpResponse.out`. When the response stream is closed, it writes the `Content-Length` and pipes the buffer to the real HTTP response. This is part of [HTTP optimisation](http://stackoverflow.com/questions/2419281/content-length-header-versus-chunked-encoding).

Response buffering may be disabled on a per request / response basis by calling:

```
HttpResponse.disableBuffering()
```

A threshold can be set, whereby if the buffer size exeeds that value, all content is streamed directly to the client. See [responseBufferThreshold](http://pods.fantomfactory.org/pods/afBedSheet/api/BedSheetConfigIds.responseBufferThreshold) for more details.

## Development Proxy

Never (manually) restart your app again!

Use the `-proxy` option when starting BedSheet to create a development Proxy and your app will auto re-start when a pod is updated:

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

See [proxyPingInterval](http://pods.fantomfactory.org/pods/afBedSheet/api/BedSheetConfigIds.proxyPingInterval) for more details.

## Wisp Integration

To some, BedSheet may look like a behemoth web framework, but it is in fact just a standard Fantom [WebMod](http://fantom.org/doc/web/WebMod.html). This means it can be plugged into a [Wisp](http://fantom.org/doc/wisp/index.html) application along side other all the other standard [webmods](http://fantom.org/doc/webmod/index.html). Just create an instance of [BedSheetWebMod](http://pods.fantomfactory.org/pods/afBedSheet/api/BedSheetWebMod) and pass it to Wisp like any other.

For example, the following Wisp application places BedSheet under the path `poo/`.

```
using concurrent
using wisp
using webmod
using afIoc
using afBedSheet

class Example {
    Void main() {
        bob := BedSheetBuilder(AppModule#.qname)
        reg := bob.build.startup
        mod := RouteMod { it.routes = [
            "poo" : BedSheetWebMod(reg)
        ]}

        WispService { it.port=8069; it.root=mod }.install.start

        Actor.sleep(Duration.maxVal)
    }
}

** A tiny BedSheet app that returns 'Hello Mum!' for every request.
class TinyBedAppModule {
    @Contribute { serviceType=Routes# }
    static Void contributeRoutes(Configuration conf) {
        conf.add(Route(`/***`, Text.fromPlain("Hello Mum!")))
    }
}
```

When run, a request to `http://localhost:8069/` will return a Wisp 404 and any request to `http://localhost:8069/poo/*` will invoke BedSheet and return `Hello Mum!`.

When running BedSheet under a non-root path, be sure to transform all link hrefs with [BedSheetServer.toClientUrl()](http://pods.fantomfactory.org/pods/afBedSheet/api/BedSheetServer#toClientUrl) to ensure the extra path info is added. Similarly, ensure asset URLs are retrieved from the [FileHandler](http://pods.fantomfactory.org/pods/afBedSheet/api/FileHandler) service.

Note that each mulitple BedSheet instances may be run side by side in the same Wisp application.

## Go Live with Heroku

In a hurry to go live? Use [Heroku](http://www.heroku.com/)!

[Heroku](http://www.heroku.com/) and the [heroku-fantom-buildpack](https://bitbucket.org/AlienFactory/heroku-buildpack-fantom) makes it ridiculously to deploy your web app to a live server. Just check in your code and Heroku will build your web app from source and deploy it to a live environment!

To have Heroku run your BedSheet web app you have 2 options:

1. Create a Heroku text file called `Procfile` at the same level as your `build.fan` with the following line:

        web: fan afBedSheet <app-name> $PORT



  substituting `<app-name>` with your fully qualified app module name. Type `$PORT` verbatim, as it is. Example:



        web: fan afBedSheet acme::AppModule $PORT



  Now Heroku will start BedSheet, passing in your app name.



  OR


2. Create a `Main` class in your app:

        using util
        
        class Main : AbstractMain {
        
            @Arg { help="The HTTP port to run the app on" }
            private Int port
        
            override Int run() {
                BedSheetBuilder(AppModule#.qname).startWisp(port)
            }
        }



  Main classes have the advantage of being easy to run from an IDE or cmd line.



  See [heroku-fantom-buildpack](https://bitbucket.org/AlienFactory/heroku-buildpack-fantom) for more details.



## Tips

All route handlers and processors are built by [IoC](http://pods.fantomfactory.org/pods/afIoc) so feel free to `@Inject` DAOs and other services.

BedSheet itself is built with [IoC](http://pods.fantomfactory.org/pods/afIoc) so look at the [BedSheet Source](https://bitbucket.org/AlienFactory/afbedsheet/src) for [IoC](http://pods.fantomfactory.org/pods/afIoc) examples.

Even if your route handlers aren't services, if they're `const` classes, they're cached by BedSheet and reused on every request.

