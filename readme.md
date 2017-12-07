#BedSheet v1.5.8
---

[![Written in: Fantom](http://img.shields.io/badge/written%20in-Fantom-lightgray.svg)](http://fantom-lang.org/)
[![pod: v1.5.8](http://img.shields.io/badge/pod-v1.5.8-yellow.svg)](http://www.fantomfactory.org/pods/afBedSheet)
![Licence: ISC Licence](http://img.shields.io/badge/licence-ISC Licence-blue.svg)

## Overview

BedSheet is a platform for delivering web applications written in [Fantom](http://fantom.org/). It provides a rich middleware mechanism for the routing and delivery of content over HTTP.

- **An IoC Container** - BedSheet applications are IoC applications
- **Proxy Mode** - Never (manually) restart your application again!
- **Routing** - Map URLs to Fantom methods
- **Route Handlers** - Map URLs to file system and pod resources
- **Error Handling** - Customised error handling and detailed error reporting
- **Status Pages** - Customise 404 and 500 pages

BedSheet is built on top of [IoC](http://eggbox.fantomfactory.org/pods/afIoc) and [Wisp](http://fantom.org/doc/wisp/index.html), and was inspired by Java's [Tapestry5](http://tapestry.apache.org/) and Ruby's [Sinatra](http://www.sinatrarb.com/).

## Install

Install `BedSheet` with the Fantom Pod Manager ( [FPM](http://eggbox.fantomfactory.org/pods/afFpm) ):

    C:\> fpm install afBedSheet

Or install `BedSheet` with [fanr](http://fantom.org/doc/docFanr/Tool.html#install):

    C:\> fanr install -r http://eggbox.fantomfactory.org/fanr/ afBedSheet

To use in a [Fantom](http://fantom-lang.org/) project, add a dependency to `build.fan`:

    depends = ["sys 1.0", ..., "afBedSheet 1.5"]

## Documentation

Full API & fandocs are available on the [Eggbox](http://eggbox.fantomfactory.org/pods/afBedSheet/) - the Fantom Pod Repository.

## Quick Start

1. Create a text file called `Example.fan`:

        using afIoc
        using afBedSheet
        
        class HelloPage {
            Text hello(Str name, Int iq := 666) {
                return Text.fromPlain("Hello! I'm $name and I have an IQ of $iq!")
            }
        }
        
        const class AppModule {
            @Contribute { serviceType=Routes# }
            Void contributeRoutes(Configuration conf) {
                conf.add(Route(`/index`, Text.fromHtml("<html><body>Welcome to BedSheet!</body></html>")))
                conf.add(Route(`/hello/**`, HelloPage#hello))
            }
        }
        
        class Example {
            Int main() {
                BedSheetBuilder(AppModule#).startWisp(8080)
            }
        }


2. Run `Example.fan` as a Fantom script from the command line:

        C:\> fan Example.fan -env development
        
        [info] [afBedSheet] Found mod 'Example_0::AppModule'
        [info] [afBedSheet] Starting Bed App 'Example_0' on port 8080
        [info] [web] http started on port 8080
        [info] [afIoc] Adding module afIoc::IocModule
        [info] [afIoc] Adding module Example_0::AppModule
        [info] [afIoc] Adding module afBedSheet::BedSheetModule
        [info] [afIoc] Adding module afIocConfig::IocConfigModule
        [info] [afIoc] Adding module afBedSheet::BedSheetEnvModule
        [info] [afIoc] Adding module afConcurrent::ConcurrentModule
        [info] [afIocEnv] Setting from cmd line argument '-env' : development
        ...
        
        24.32% of services were built on startup (9/37)
        
           ___    __                 _____        _
          / _ |  / /_____  _____    / ___/__  ___/ /_________  __ __
         / _  | / // / -_|/ _  /===/ __// _ \/ _/ __/ _  / __|/ // /
        /_/ |_|/_//_/\__|/_//_/   /_/   \_,_/__/\__/____/_/   \_, /
                   Alien-Factory BedSheet v1.5.0, IoC v3.0.0 /___/
        
        
        [info] [afIoc] IoC Registry built in 91ms and started up in 96ms
        
        Bed App 'Example_0' listening on http://localhost:8080/


3. Visit `localhost` to hit the web application:

        C:\> curl http://localhost:8080/index
        <html><body>Welcome to BedSheet!</body></html>
        
        C:\> curl http://localhost:8080/hello/Traci/69
        Hello! I'm Traci and I have an IQ of 69!
        
        C:\> curl http://localhost:8080/hello/Luci
        Hello! I'm Luci and I have an IQ of 666!



Wow! That's awesome! But what just happened!?

Every BedSheet application has an `AppModule` that configures [IoC](http://eggbox.fantomfactory.org/pods/afIoc) services. Here we told the `Routes` service to return some plain text in response to `/index` and to call the `HelloPage#hello` method for all requests that start with `/hello`. [Route](http://eggbox.fantomfactory.org/pods/afBedSheet/api/Route) converts URL path segments into method arguments, or in our case, to `Str name` and to an optional `Int iq`.

Route handlers are typically what we, the application developers, write. They perform logic processing and render responses. Our `HelloPage` route handler simply returns a plain [Text](http://eggbox.fantomfactory.org/pods/afBedSheet/api/Text) response, which BedSheet sends to the client via an appropriate [ResponseProcessor](http://eggbox.fantomfactory.org/pods/afBedSheet/api/ResponseProcessor).

## Starting BedSheet

You can start BedSheet manually, as we did in the Quick Start example, or you can [start BedSheet from the command line](http://eggbox.fantomfactory.org/pods/afBedSheet/api/Main). Just tell it where to find an `AppModule` and the port to run on:

```
C:\> fan afBedSheet [-port <port>] [-env <env>] [-proxy] <qualified-appModule-name>
```

For example:

```
C:\> fan afBedSheet -port 8069 myWebApp::AppModule
```

Every Bed App (BedSheet Application) has an `AppModule` class that defines and configures your [IoC](http://eggbox.fantomfactory.org/pods/afIoc) services. It is an IoC concept that allows you centralise your application's configuration in one place. It is the `AppModule` that defines your Bed App and is central everything it does.

`<qualified-appModule-name>` may be replaced with just `<pod-name>` as long as your pod's `build.fan` defines the following meta:

```
meta = [
    ...
    ...
    "afIoc.module" : "<qualified-appModule-name>"
]
```

This allows BedSheet to look up your `AppModule` from the pod. Example:

```
C:\> fan afBedSheet -port 8069 myWebApp
```

Note that the `AppModule` class is named so out of convention but may be called anything you like.

See [Development Proxy](#developmentProxy) for info on the `-proxy` option.

## IoC Container

BedSheet is an IoC container. That is, it creates and looks after a `Registry` instance, using it to create classes and provide access to services.

[BedSheet](http://eggbox.fantomfactory.org/pods/afBedSheet) Web applications are multi-threaded; each web request is served on a different thread. For that reason BedSheet defines a threaded scope called `request`.

By default const services are matched to the root scope and non-const services are matched the to request scope. But it it better to be explicit and set which scopes a service is available on when it is defined.

```
class AppModule {
    Void defineServices(RegistryBuilder bob) {
        bob.addService(MyService1#).withScope("root")

        bob.addService(MyService2#).withScope("request")
    }
}
```

### Root Scope

In IoC's default `root` scope, only one instance of the service is created for the entire application. It is how you share data and services between requests and threads. *Root scoped* services need to be `const` classes.

### Request Scope

In BedSheet's `request` scope a new instance of the service will be created for each thread / web request. BedSheet's `WebReq` and `WebRes` are good examples this. Note in some situations this *per thread* object creation could be considered wasteful. In other situations, such as sharing database connections, it is not even viable.

Writing `const` services (for the root scope) may be off-putting - because they're constant and can't hold mutable data, right!? ** *Wrong!* ** Const classes *can* hold *mutable* data. See the Maps and Lists in Alien-Factory's [Concurrent](http://eggbox.fantomfactory.org/pods/afConcurrent) pod for examples. The article [From One Thread to Another...](http://www.alienfactory.co.uk/articles/from-one-thread-to-another) explains the principles in more detail.

The smart ones may be thinking that `root` scoped services can only hold other `root` scoped services. Well, they would be wrong too! Using IoC's active scope and the magic of IoC's *Lazy Funcs*, `request` scoped services may be injected into `root` scoped services. See IoC's Lazy Funcs for more info.

## Request Routing

The `Routes` service maps HTTP request URLs to response objects and handler methods. It is where you would typically define how requests are handled. You configure the `Routes` service by contributing instances of [Route](http://eggbox.fantomfactory.org/pods/afBedSheet/api/Route). Example:

```
using afIoc
using afBedSheet

class AppModule {

    @Contribute { serviceType=Routes# }
    Void contributeRoutes(Configuration config) {

        config.add(Route(`/home`,  Redirect.movedTemporarily(`/index`)))
        config.add(Route(`/index`, IndexPage#service))
        config.add(Route(`/work`,  WorkPage#service, "POST"))
    }
}
```

[Route](http://eggbox.fantomfactory.org/pods/afBedSheet/api/Route) objects take a matching `glob` and a response object. A response object is any object that BedSheet knows how to [process](#responseObjects) or a `Method` to be called. If a method is given, then request URL path segments are matched to the method parameters. See [Route](http://eggbox.fantomfactory.org/pods/afBedSheet/api/Route) for more details.

Note that `Route` is actually a mixin, so you can create custom instances that match on anything, not just URLs.

Routing lesson over.

(...you Aussies may stop giggling now.)

## Route Handling

*Route Handler* is the name given to a class or method that is processed by a `Route`. They process logic and generally don't pipe anything to the HTTP response stream. Instead they return a *Response Object* for further processing. For example, the [Quick Start](#quickStart) `HelloPage` *route handler* returns a [Text](http://eggbox.fantomfactory.org/pods/afBedSheet/api/Text) *response object*.

Route handlers are written by the application developer, but a couple of common use-cases are bundled with BedSheet:

- [FileHandler](http://eggbox.fantomfactory.org/pods/afBedSheet/api/FileHandler): Maps request URLs to files on the file system.
- [PodHandler](http://eggbox.fantomfactory.org/pods/afBedSheet/api/PodHandler) : Maps request URLs to pod file resources.

See the [FileHandler](http://eggbox.fantomfactory.org/pods/afBedSheet/api/FileHandler) documentation for examples on how to serve up static files. If no configuration is given to `FileHandler` then it defaults to serving files from the `etc/web-static/` directory.

See the [PodHandler](http://eggbox.fantomfactory.org/pods/afBedSheet/api/PodHandler) documentation for examples on how to serve up static pod files, including Fantom generated Javascript.

(Note that, as of BedSheet 1.4.10, `FileHandler` and `PodHandler` are actually processed by Asset Middleware and not Routes.)

## Response Objects

*Response Objects* are returned from *Route Handlers*. It is then the job of [Response Processors](http://eggbox.fantomfactory.org/pods/afBedSheet/api/ResponseProcessor) to process these objects, converting them into data to be sent to the client. *Response Processors* may themselves return *Response Objects*, which will be handled by another *Response Processor*.

You can define *Response Processors* and process *Response Objects* yourself; but by default, BedSheet handles the following:

- `Void` / `null` / `false` : Processing should fall through to the next Route match.
- `true` : No further processing is required.
- [Asset](http://eggbox.fantomfactory.org/pods/afBedSheet/api/Asset) : The asset is piped to the client.
- [ClientAsset](http://eggbox.fantomfactory.org/pods/afBedSheet/api/ClientAsset) : Caching and identity headers are set and the asset piped to the client.
- [Err](http://fantom.org/doc/sys/Err.html) : An appropriate response object is selected from contributed Err responses. (See [Error Processing](#errorProcessing).)
- [Field](http://fantom.org/doc/sys/Field.html) : The field value is returned for further processing. (*)
- [File](http://fantom.org/doc/sys/File.html) : The file is piped to the client.
- [Func](http://fantom.org/doc/sys/Func.html) : The function is called, using IoC to inject the parameters. The return value is treated as a new reposonse object for further processing.
- [HttpStatus](http://eggbox.fantomfactory.org/pods/afBedSheet/api/HttpStatus) : An appropriate response object is selected from contributed HTTP status responses. (See [HTTP Status Processing](#httpStatusProcessing).)
- [InStream](http://fantom.org/doc/sys/InStream.html) : The `InStream` is piped to the client. The `InStream` is guaranteed to be closed.
- [MethodCall](http://eggbox.fantomfactory.org/pods/afBedSheet/api/MethodCall) : The method is called and the return value used for further processing. (*)
- [Redirect](http://eggbox.fantomfactory.org/pods/afBedSheet/api/Redirect) : Sends a 3xx redirect response to the client.
- [Text](http://eggbox.fantomfactory.org/pods/afBedSheet/api/Text) : The text (be it plain, json, xml, etc...) is sent to the client with a corresponding `Content-Type`.

Because of the nature of response object processing it is possible, nay normal, to *chain* multiple response objects together. Example:

1. If a Route returns or throws an `Err`,
2. `ErrProcessor` looks up its responses and returns a `Func`,
3. `FuncProcessor` calls a handler method which returns a `Text`,
4. `TextProcessor` serves content to the client and returns `true`.

Note that response object processing is extensible, just contribute your own [Response Processor](http://eggbox.fantomfactory.org/pods/afBedSheet/api/ResponseProcessor).

(*) If the slot is not static, then if the parent class:

- is a service then it is retrieved from IoC,
- is `const` then a single instance is created, used, and cached for future use,
- is not `const` then an instance is created, used, and discarded.

## Template Rendering

Templating, or formatting text (HTML or otherwise) is left for other 3rd party libraries and is not a conern of BedSheet. That said, there a couple templating libraries *out there* and integrating them into BedSheet is relatively simple. For instance, Alien-Factory provides the following libraries:

- [efan](http://eggbox.fantomfactory.org/pods/afEfan) for basic templating,
- [Slim](http://eggbox.fantomfactory.org/pods/afSlim) for concise HTML templating, and
- [Pillow](http://eggbox.fantomfactory.org/pods/afPillow) for integrating [efanXtra](http://eggbox.fantomfactory.org/pods/afEfanXtra) components (may be used with [Slim](http://eggbox.fantomfactory.org/pods/afSlim)!)

Taking [Slim](http://eggbox.fantomfactory.org/pods/afSlim) as an example, simply inject the Slim service into your *Route Handler* and use it to return a `Text` response object:

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

When a HTTP request is received, it is passed through a pipeline of BedSheet [Middleware](http://eggbox.fantomfactory.org/pods/afBedSheet/api/Middleware); this is a similar to [Java Servlet Filters](http://docs.oracle.com/javaee/5/api/javax/servlet/Filter.html). If the request reaches the end of the pipeline without being processed, a 404 is returned.

Middleware bundled with BedSheet include:

- `RequestLoggers`: For logging HTTP request / responses.
- `Routes` : Performs the standard [request routing](#requestRouting)

You can define your own middleware to address cross cutting concerns such as authentication and authorisation. See the FantomFactory article [Basic HTTP Authentication With BedSheet](http://www.alienfactory.co.uk/articles/basic-http-authentication-with-bedSheet) for working examples.

## Error Processing

When BedSheet catches an Err it scans through a list of contributed response objects to find one that can handle the Err. If no matching response object is found then the *default err response object* is used. This default response object displays BedSheet's extremely verbose Error 500 page. It displays (a shed load of) debugging information and is highly customisable:

![BedSheet's Verbose Err500 Page](data:image/png;base64,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)

The BedSheet Err page is great for development, but not so great for production - stack traces tend to scare Joe Public! So note that in a production environment (see [IocEnv](http://eggbox.fantomfactory.org/pods/afIocEnv)) a simple HTTP status page is displayed instead.

> **ALIEN-AID:** BedSheet defaults to production mode, so to see the verbose error page you must switch to development mode. The easiest way to do this is to set an environment variable called `ENV` with the value `development`. See [IocEnv](http://eggbox.fantomfactory.org/pods/afIocEnv) details.

To handle a specific Err, contribute a response object to `ErrResponses`:

```
@Contribute { serviceType=ErrResponses# }
Void contributeErrResponses(Configuration config) {
    config[ArgErr#] = MethodCall(MyErrHandler#process).toImmutableFunc
}
```

Note that in the above example, `ArgErr` and all subclasses of `ArgErr` will be processed by `MyErrHandler.process()`. A contribution for just `Err` will act as a capture all and be used should a more precise match not be found.

You can also replace the default err response object:

```
@Contribute { serviceType=ApplicationDefaults# }
Void contributeApplicationDefaults(Configuration config) {
    config[BedSheetConfigIds.defaultErrResponse] = Text.fromHtml("<html><b>Oops!</b></html>")
}
```

When processing an Err, note that the thrown `Err` is stored in `HttpRequest.stash`. It may be retrieved by handlers with the following:

    err := (Err) httpRequest.stash["afBedSheet.err"]

## HTTP Status Processing

`HttpStatus` objects are handled by a [ResponseProcessor](http://eggbox.fantomfactory.org/pods/afBedSheet/api/ResponseProcessor) that selects a contributed response object that corresponds to the HTTP status code. If no specific response object is found then the *default http status response object* is used. This default response object displays BedSheet's HTTP Status Code page. This is what you see when you receive a `404 Not Found` error.

![BedSheet's 404 Status Page](data:image/png;base64,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)

To set your own `404 Not Found` page contribute a response object to the `HttpStatusResponses` service with the status code `404`:

```
@Contribute { serviceType=HttpStatusResponses# }
Void contribute404Response(Configuration config) {
    config[404] = MethodCall(Error404Page#process).toImmutableFunc
}
```

In the above example, all 404 status codes will be processed by `Error404Page.process()`.

To replace *all* status code responses, replace the default HTTP status response object:

```
@Contribute { serviceType=ApplicationDefaults# }
Void contributeApplicationDefaults(Configuration config) {
    config[BedSheetConfigIds.defaultHttpStatusResponse] = Text.fromHtml("<html>Error</html>")
}
```

`HttpStatus` objects are stored in the `HttpRequest.stash` map and may be retrieved by handlers with the following:

    httpStatus := (HttpStatus) httpRequest.stash["afBedSheet.httpStatus"]

## Config Injection

BedSheet uses [IoC Config](http://eggbox.fantomfactory.org/pods/afIocConfig) to give injectable `@Config` values. `@Config` values are essentially a map of Str to immutable / constant values that may be set and overriden at application start up. (Consider config values to be immutable once the app has started).

BedSheet sets the initial config values by contributing to the `FactoryDefaults` service. An application may then override these values by contributing to the `ApplicationDefaults` service.

```
@Contribute { serviceType=ApplicationDefaults# }
Void contributeApplicationDefaults(Configuration conf) {
    ...
    conf["afBedSheet.errPrinter.noOfStackFrames"] = 100
    ...
}
```

All BedSheet config keys are listed in [BedSheetConfigIds](http://eggbox.fantomfactory.org/pods/afBedSheet/api/BedSheetConfigIds) meaning the above can be more safely rewriten as:

```
conf[BedSheetConfigIds.noOfStackFrames] = 100
```

To inject config values in your services, use the `@Config` facet with conjunction with [IoC](http://eggbox.fantomfactory.org/pods/afIoc)'s `@Inject`:

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
    Void contributeRoutes(Configuration conf) {
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
        json := httpRequest.body.jsonMap

        // return a different status code, e.g. 201 - Created
        httpResponse.statusCode = 201

        // return plain text or JSON objects to the client
        return Text.fromPlainText("OK")
    }
}
```

## File Uploading

File uploading can be pretty horrendous in other languages, but here in Fantom land it's pretty easy.

First create your HTML, here's a form snippet:

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
    Void contributeRoutes(Configuration conf) {
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

BedSheet has a hook for logging HTTP requests. Just implement [RequestLogger](http://eggbox.fantomfactory.org/pods/afBedSheet/api/RequestLogger) and contribute it to the `RequestLoggers` service. This service ensures the loggers are able to log what gets sent to the browser, without interruption from the error handling framework.

Example, this simple logger generates standard HTTP request log files in the [W3C Extended Log File Format](http://www.w3.org/TR/WD-logfile.html).

```
using webmod

const class W3CLogger : RequestLogger {
    private const LogMod logMod

    new make() {
        logMod = LogMod {
            it.dir      = File.os("C:\\temp\\logs\\")    // note the trailing slash!
            it.filename = "afBedSheet-{YYYY-MM}.log"
            it.fields   = "date time c-ip cs(X-Real-IP) cs-method cs-uri-stem cs-uri-query sc-status time-taken cs(User-Agent) cs(Referer) cs(Cookie)"
        }
        logMod.onStart
    }

    override Void logOutgoing() {
        logMod.onService
    }
}
```

To enable, add the `W3CLogger` to the `RequestLoggers` service

```
@Contribute { serviceType=RequestLoggers# }
Void contributeRequestLoggers(Configuration config) {
    config.add(MyRequestLogger())
}
```

The log files will then look something like the following, see [webmod::LogMod](http://fantom.org/doc/webmod/LogMod.html) for more details.

```
2013-02-22 13:13:13 127.0.0.1 - GET /doc - 200 222 "Mozilla/5.0" "http://localhost/index"

```

### Default Logger

BedSheet ships with a basic default logger that times each request. To enable, turn on BedSheet debug logging. You can do this in code with:

    Log.get("afBedSheet").level = LogLevel.debug

Or you can enable it for the environment by adding the following to `%FAN_HOME%\etc\sys\log.props`

    afBedSheet = debug

Then you should see output like this in your console:

```
[debug] [afBedSheet] GET  /about --------------------------------------------------> 200 (in 21ms)
[debug] [afBedSheet] GET  /coldFeet/nx6lXQ==/css/website.min.css ------------------> 200 (in  6ms)
[debug] [afBedSheet] GET  /pods ---------------------------------------------------> 200 (in 52ms)
[debug] [afBedSheet] GET  /pods/whoops --------------------------------------------> 404 (in 28ms)
```

## Gzip

BedSheet compresses HTTP responses with gzip where it can for [HTTP optimisation](http://betterexplained.com/articles/how-to-optimize-your-site-with-gzip-compression/). Gzipping in BedSheet is highly configurable.

Gzip may be disabled for the entire web app by setting the following config property:

```
@Contribute { serviceType=ApplicationDefaults# }
Void contributeApplicationDefaults(Configuration config) {
    config[BedSheetConfigIds.gzipDisabled] = true
}
```

Or Gzip can be disabled on a per request / response basis by calling:

```
HttpResponse.disableGzip()
```

Text files gzip very well and yield high compression rates, but not everything should be gzipped. For example, JPG images are already compressed when gzip'ed often end up larger than the original! For this reason only [Mime Types](http://fantom.org/doc/sys/MimeType.html) contributed to the `GzipCompressible` service will be gzipped.

Most standard compressible types are already contributed to `GzipCompressible` including html, css, javascript, json, xml and other text responses. You may contribute your own with:

```
@Contribute { serviceType=GzipCompressible# }
Void configureGzipCompressible(Configuration config) {
    config[MimeType("text/funky")] = true
}
```

Guaranteed that someone, somewhere is still using Internet Explorer 3.0 - or some other client that can't handle gzipped content from the server. As such, and as per [RFC 2616 HTTP1.1 Sec14.3](http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.3), the response is only gzipped if the appropriate HTTP request header was set.

Gzip is great when compressing large files, but if you've only got a few bytes to squash... then the compressed version is going to be bigger than the original - which kinda defeats the point compression! For that reason the response data must reach a minimum size / threshold before it gets gzipped. See [gzipThreshold](http://eggbox.fantomfactory.org/pods/afBedSheet/api/BedSheetConfigIds.gzipThreshold) for more details.

## Buffered Response

If a `Content-Length` header was not supplied then BedSheet attempts to calculate it by buffering `HttpResponse.out`. When the response stream is closed, it writes the `Content-Length` and pipes the buffer to the real HTTP response. This is part of [HTTP optimisation](http://stackoverflow.com/questions/2419281/content-length-header-versus-chunked-encoding).

Response buffering may be disabled on a per request / response basis by calling:

```
HttpResponse.disableBuffering()
```

A threshold can be set, whereby if the buffer size exeeds that value, all content is streamed directly to the client. See [responseBufferThreshold](http://eggbox.fantomfactory.org/pods/afBedSheet/api/BedSheetConfigIds.responseBufferThreshold) for more details.

## Development Proxy

Never (manually) restart your app again!

Use the `-proxy` option when starting BedSheet to create a development Proxy and your app will auto re-start whenever a pod is updated:

```
C:\> fan afBedSheet -port <port> -proxy <appModule>
```

The proxy sits on `(port)` and starts the real app on `(port+1)`, forwarding all requests to it.

Each time the web browser makes a request, it connects to the proxy which forwards it to the real web app.

```
.                |---> Web App (port+1)
Proxy (port) <-->|
                 |<--- Web Browser
```

On each request, the proxy scans the pod files in the Fantom environment, and should any of them be updated, it restarts the web application.

```
.                |<--> RESTART
Proxy (port) <-->|
                 |<--> Web Browser
```

Note that the proxy is intelligent enough to only scan those pods used by the web application. If need be, use the [-watchAllPods](http://eggbox.fantomfactory.org/pods/afBedSheet/api/Main) option to watch *all* pods.

A problem other web frameworks (*cough* *draft*) suffer from is that, when the proxy dies, your real web app is left hanging around; requiring you to manually kill it. Which can be both confusing and annoying.

```
.                |<--> Web App (port+1)
             ??? |
                 |<--> Web Browser
```

BedSheet applications go a step further and, should it be started in proxy mode, it pings the proxy every second to stay alive. Should the proxy not respond, the web app kills itself.

See [proxyPingInterval](http://eggbox.fantomfactory.org/pods/afBedSheet/api/BedSheetConfigIds.proxyPingInterval) for more details.

## Wisp Integration

To some, BedSheet may look like a behemoth web framework, but it is in fact just a standard Fantom [WebMod](http://fantom.org/doc/web/WebMod.html). This means it can be plugged into a [Wisp](http://fantom.org/doc/wisp/index.html) application along side other all the other standard [webmods](http://fantom.org/doc/webmod/index.html). Just create an instance of [BedSheetWebMod](http://eggbox.fantomfactory.org/pods/afBedSheet/api/BedSheetWebMod) and pass it to Wisp like any other.

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
        mod := RouteMod { it.routes = [
            "poo" : BedSheetWebMod(bob.build)
        ]}

        WispService { it.port=8069; it.root=mod }.install.start

        Actor.sleep(Duration.maxVal)
    }
}

** A tiny BedSheet app that returns 'Hello Mum!' for every request.
const class TinyBedAppModule {
    @Contribute { serviceType=Routes# }
    static Void contributeRoutes(Configuration conf) {
        conf.add(Route(`/***`, Text.fromPlain("Hello Mum!")))
    }
}
```

When run, a request to `http://localhost:8069/` will return a Wisp 404 and any request to `http://localhost:8069/poo/*` will invoke BedSheet and return `Hello Mum!`.

When running BedSheet under a non-root path, be sure to transform all link hrefs with [BedSheetServer.toClientUrl()](http://eggbox.fantomfactory.org/pods/afBedSheet/api/BedSheetServer.toClientUrl) to ensure the extra path info is added. Similarly, ensure asset URLs are retrieved from the [FileHandler](http://eggbox.fantomfactory.org/pods/afBedSheet/api/FileHandler) service.

Note that mulitple BedSheet instances may be run side by side in the same Wisp application.

## SkySpark Integration

BedSheet can also be seemlessly run as [SkySpark Web Extension](https://skyfoundry.com/doc/docSkySpark/Exts#extClass)

Following is a SkySpark Web [Ext](https://skyfoundry.com/doc/skyarcd/Ext) that delegates all web requests to BedSheet.

```
using skyarcd::Ext
using skyarcd::ExtMeta
using concurrent::AtomicRef
using afIoc
using afBedSheet::MiddlewarePipeline
using web::Weblet

@ExtMeta { name = "myExtensionName" }
const class BedSheetExt : Ext, Weblet {

    private const AtomicRef    registryRef := AtomicRef(null)
    private Registry           registry {
        get { registryRef.val }
        set { registryRef.val = it }
    }

    private const AtomicRef    pipelineRef := AtomicRef(null)
    private MiddlewarePipeline pipeline {
        get { pipelineRef.val }
        set { pipelineRef.val = it }
    }

    override Void onStart() {
        this.registry = RegistryBuilder().addModulesFromPod("afBedSheet").addModule(AppModule#).build
        this.pipeline = registry.activeScope.serviceById(MiddlewarePipeline#.qname)
    }

    override Void onService() {
        registry.activeScope.createChild("request") {
            // this is the actual call to BedSheet!
            pipeline.service
        }
    }

    override Void onStop() {
        registry.shutdown
    }
}
```

`onStart()` creates the IoC registry based on your `AppModule` and caches BedSheet's `MiddlewarePipeline` service. A new IoC web `request` scope is created on every web request and the BedSheet pipeline is used to service it.

`onStop()` then just shuts down the IoC registry, and hence BedSheet also.

Note that SkySpark will need the BedSheet pod, and all its dependencies, in its `/lib/fan/` dir (or some other environment lib dir). How you maintain and distribute these with your SkySpark application is then up to you.

## Go Live!

### ...with Heroku

In a hurry to go live? Use [Heroku](http://www.heroku.com/)!

The [heroku-fantom-buildpack](https://bitbucket.org/AlienFactory/heroku-buildpack-fantom) makes it ridiculously to deploy your web app to a live server. Just check in your code and Heroku will build your web app from source and deploy it to a live environment!

See the [Fantom Buildpack for Heroku](https://bitbucket.org/AlienFactory/heroku-buildpack-fantom) for more details.

### ...with OpenShift

In a hurry to go live? Use [OpenShift](https://www.openshift.com/)! RedHat's OpenShift [Origin](https://www.openshift.org/) is a cloud PaaS with free plans. Just check in your code and OpenShift will build your web app from source and deploy it to a live environment!

See Alien-Factory's [Fantom Quickstart for OpenShift](https://bitbucket.org/AlienFactory/openshift-fantom-quickstart) template for details on how to deploy your BedSheet application to OpenShift.

## Tips

All route handlers and processors are built by [IoC](http://eggbox.fantomfactory.org/pods/afIoc) so feel free to `@Inject` DAOs and other services.

BedSheet itself is built with [IoC](http://eggbox.fantomfactory.org/pods/afIoc) so look at the [BedSheet Source](https://bitbucket.org/AlienFactory/afbedsheet/src) for [IoC](http://eggbox.fantomfactory.org/pods/afIoc) examples.

Even if your route handlers aren't services, if they're `const` classes, they're cached by BedSheet and reused on every request.

