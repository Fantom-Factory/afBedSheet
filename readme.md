# BedSheet v1.5.20
---

[![Written in: Fantom](http://img.shields.io/badge/written%20in-Fantom-lightgray.svg)](https://fantom-lang.org/)
[![pod: v1.5.20](http://img.shields.io/badge/pod-v1.5.20-yellow.svg)](https://eggbox.fantomfactory.org/pods/afBedSheet)
[![Licence: ISC](http://img.shields.io/badge/licence-ISC-blue.svg)](https://choosealicense.com/licenses/isc/)

## Overview

BedSheet is a platform for delivering web applications written in [Fantom](http://fantom-lang.org/). It provides a rich middleware mechanism for the routing and delivery of content over HTTP.

* **An IoC Container** - BedSheet applications are IoC applications
* **Proxy Mode** - Never (manually) restart your application again!
* **Routing** - Map URLs to Fantom methods
* **Route Handlers** - Map URLs to file system and pod resources
* **Error Handling** - Customised error handling and detailed error reporting
* **Status Pages** - Customise 404 and 500 pages


BedSheet is built on top of [IoC](http://eggbox.fantomfactory.org/pods/afIoc) and [Wisp](https://fantom.org/doc/wisp/index.html), and was inspired by Java's [Tapestry5](http://tapestry.apache.org/) and Ruby's [Sinatra](http://www.sinatrarb.com/).

## <a name="Install"></a>Install

Install `BedSheet` with the Fantom Pod Manager ( [FPM](http://eggbox.fantomfactory.org/pods/afFpm) ):

    C:\> fpm install afBedSheet

Or install `BedSheet` with [fanr](https://fantom.org/doc/docFanr/Tool.html#install):

    C:\> fanr install -r http://eggbox.fantomfactory.org/fanr/ afBedSheet

To use in a [Fantom](https://fantom-lang.org/) project, add a dependency to `build.fan`:

    depends = ["sys 1.0", ..., "afBedSheet 1.5"]

## <a name="documentation"></a>Documentation

Full API & fandocs are available on the [Eggbox](http://eggbox.fantomfactory.org/pods/afBedSheet/) - the Fantom Pod Repository.

## <a name="quickStart"></a>Quick Start

1. Create a text file called `Example.fan`:    using afIoc
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
            conf.add(Route(`/hello/*/*`, HelloPage#hello))
        }
    }
    
    class Example {
        Int main() {
            BedSheetBuilder(AppModule#).startWisp(8080)
        }
    }


2. Run `Example.fan` as a Fantom script from the command line:    C:\> fan Example.fan -env development
    
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


3. Visit `localhost` to hit the web application:    C:\> curl http://localhost:8080/index
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

    C:\> fan afBedSheet [-port <port>] [-env <env>] [-proxy] <qualified-appModule-name>
    

For example:

    C:\> fan afBedSheet -port 8069 myWebApp::AppModule
    

Every Bed App (BedSheet Application) has an `AppModule` class that defines and configures your [IoC](http://eggbox.fantomfactory.org/pods/afIoc) services. It is an IoC concept that allows you centralise your application's configuration in one place. It is the `AppModule` that defines your Bed App and is central everything it does.

`<qualified-appModule-name>` may be replaced with just `<pod-name>` as long as your pod's `build.fan` defines the following meta:

    meta = [
        ...
        ...
        "afIoc.module" : "<qualified-appModule-name>"
    ]
    

This allows BedSheet to look up your `AppModule` from the pod. Example:

    C:\> fan afBedSheet -port 8069 myWebApp
    

Note that the `AppModule` class is named so out of convention but may be called anything you like.

See [Development Proxy](#developmentProxy) for info on the `-proxy` option.

## IoC Container

BedSheet is an IoC container. That is, it creates and looks after a `Registry` instance, using it to create classes and provide access to services.

[BedSheet](http://eggbox.fantomfactory.org/pods/afBedSheet) Web applications are multi-threaded; each web request is served on a different thread. For that reason BedSheet defines a threaded scope called `request`.

By default const services are matched to the root scope and non-const services are matched the to request scope. But it it better to be explicit and set which scopes a service is available on when it is defined.

    class AppModule {
        Void defineServices(RegistryBuilder bob) {
            bob.addService(MyService1#).withScope("root")
    
            bob.addService(MyService2#).withScope("httpRequest")
        }
    }
    

### root Scope

In IoC's default `root` scope, only one instance of the service is created for the entire application. It is how you share data and services between requests and threads. *Root scoped* services need to be `const` classes.

### httpRequest Scope

In BedSheet's `httpRequest` scope a new instance of the service will be created for each thread / web request. BedSheet's `WebReq` and `WebRes` are good examples this. Note in some situations this *per thread* object creation could be considered wasteful. In other situations, such as sharing database connections, it is not even viable.

Writing `const` services (for the root scope) may be off-putting - because they're constant and can't hold mutable data, right!? ** *Wrong!* ** Const classes *can* hold *mutable* data. See the Maps and Lists in Alien-Factory's [Concurrent](http://eggbox.fantomfactory.org/pods/afConcurrent) pod for examples. The article [From One Thread to Another...](http://www.alienfactory.co.uk/articles/from-one-thread-to-another) explains the principles in more detail.

The smart ones may be thinking that `root` scoped services can only hold other `root` scoped services. Well, they would be wrong too! Using IoC's active scope and the magic of IoC's *Lazy Funcs*, `request` scoped services may be injected into `root` scoped services. See IoC's Lazy Funcs for more info.

## <a name="requestRouting"></a>Request Routing

The `Routes` service maps HTTP request URLs to response objects and handler methods. It is where you would typically define how requests are handled. You configure the `Routes` service by contributing instances of [Route](http://eggbox.fantomfactory.org/pods/afBedSheet/api/Route). Example:

    using afIoc
    using afBedSheet
    
    class AppModule {
    
        @Contribute { serviceType=Routes# }
        Void contributeRoutes(Configuration config) {
    
            config.add(Route(`/home`,  HttpRedirect.movedTemporarily(`/index`)))
            config.add(Route(`/index`, IndexPage#service))
            config.add(Route(`/work`,  WorkPage#service, "POST"))
        }
    }
    

[Route](http://eggbox.fantomfactory.org/pods/afBedSheet/api/Route) objects take a matching `glob` and a response object. A response object is any object that BedSheet knows how to [process](#responseObjects) or a `Method` to be called. If a method is given, then request URL path segments are matched to the method parameters. See [Route](http://eggbox.fantomfactory.org/pods/afBedSheet/api/Route) for more details.

Note that `Route` is actually a mixin, so you can create custom instances that match on anything, not just URLs.

Routing lesson over.

(...you Aussies may stop giggling now.)

## Route Handling

*Route Handler* is the name given to a class or method that is processed by a `Route`. They process logic and generally don't pipe anything to the HTTP response stream. Instead they return a *Response Object* for further processing. For example, the [Quick Start](#quickStart) `HelloPage` *route handler* returns a [Text](http://eggbox.fantomfactory.org/pods/afBedSheet/api/Text) *response object*.

Route handlers are written by the application developer, but a couple of common use-cases are bundled with BedSheet:

* [FileHandler](http://eggbox.fantomfactory.org/pods/afBedSheet/api/FileHandler): Maps request URLs to files on the file system.
* [PodHandler](http://eggbox.fantomfactory.org/pods/afBedSheet/api/PodHandler) : Maps request URLs to pod file resources.


See the [FileHandler](http://eggbox.fantomfactory.org/pods/afBedSheet/api/FileHandler) documentation for examples on how to serve up static files. If no configuration is given to `FileHandler` then it defaults to serving files from the `etc/web-static/` directory.

See the [PodHandler](http://eggbox.fantomfactory.org/pods/afBedSheet/api/PodHandler) documentation for examples on how to serve up static pod files, including Fantom generated Javascript.

(Note that, as of BedSheet 1.4.10, `FileHandler` and `PodHandler` are actually processed by Asset Middleware and not Routes.)

## <a name="responseObjects"></a>Response Objects

*Response Objects* are returned from *Route Handlers*. It is then the job of [Response Processors](http://eggbox.fantomfactory.org/pods/afBedSheet/api/ResponseProcessor) to process these objects, converting them into data to be sent to the client. *Response Processors* may themselves return *Response Objects*, which will be handled by another *Response Processor*.

You can define *Response Processors* and process *Response Objects* yourself; but by default, BedSheet handles the following:

* `Void` / `null` / `false` : Processing should fall through to the next Route match.
* `true` : No further processing is required.
* [Asset](http://eggbox.fantomfactory.org/pods/afBedSheet/api/Asset) : The asset is piped to the client.
* [ClientAsset](http://eggbox.fantomfactory.org/pods/afBedSheet/api/ClientAsset) : Caching and identity headers are set and the asset piped to the client.
* [Err](https://fantom.org/doc/sys/Err.html) : An appropriate response object is selected from contributed Err responses. (See [Error Processing](#errorProcessing).)
* [Field](https://fantom.org/doc/sys/Field.html) : The field value is returned for further processing. (*)
* [File](https://fantom.org/doc/sys/File.html) : The file is piped to the client.
* [Func](https://fantom.org/doc/sys/Func.html) : The function is called, using IoC to inject the parameters. The return value is treated as a new reposonse object for further processing.
* [HttpStatus](http://eggbox.fantomfactory.org/pods/afBedSheet/api/HttpStatus) : An appropriate response object is selected from contributed HTTP status responses. (See [HTTP Status Processing](#httpStatusProcessing).)
* [InStream](https://fantom.org/doc/sys/InStream.html) : The `InStream` is piped to the client. The `InStream` is guaranteed to be closed.
* [MethodCall](http://eggbox.fantomfactory.org/pods/afBedSheet/api/MethodCall) : The method is called and the return value used for further processing. (*)
* [HttpRedirect](http://eggbox.fantomfactory.org/pods/afBedSheet/api/HttpRedirect) : Sends a 3xx redirect response to the client.
* [Text](http://eggbox.fantomfactory.org/pods/afBedSheet/api/Text) : The text (be it plain, json, xml, etc...) is sent to the client with a corresponding `Content-Type`.


Because of the nature of response object processing it is possible, nay normal, to *chain* multiple response objects together. Example:

1. If a Route returns or throws an `Err`,
2. `ErrProcessor` looks up its responses and returns a `Func`,
3. `FuncProcessor` calls a handler method which returns a `Text`,
4. `TextProcessor` serves content to the client and returns `true`.


Note that response object processing is extensible, just contribute your own [Response Processor](http://eggbox.fantomfactory.org/pods/afBedSheet/api/ResponseProcessor).

(*) If the slot is not static, then if the parent class:

* is a service then it is retrieved from IoC,
* is `const` then a single instance is created, used, and cached for future use,
* is not `const` then an instance is created, used, and discarded.


## Template Rendering

Templating, or formatting text (HTML or otherwise) is left for other 3rd party libraries and is not a conern of BedSheet. That said, there a couple templating libraries *out there* and integrating them into BedSheet is relatively simple. For instance, Alien-Factory provides the following libraries:

* [efan](http://eggbox.fantomfactory.org/pods/afEfan) for basic templating,
* [Slim](http://eggbox.fantomfactory.org/pods/afSlim) for concise HTML templating, and
* [Pillow](http://eggbox.fantomfactory.org/pods/afPillow) for integrating [efanXtra](http://eggbox.fantomfactory.org/pods/afEfanXtra) components (may be used with [Slim](http://eggbox.fantomfactory.org/pods/afSlim)!)


Taking [Slim](http://eggbox.fantomfactory.org/pods/afSlim) as an example, simply inject the Slim service into your *Route Handler* and use it to return a `Text` response object:

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
    

## BedSheet Middleware

When a HTTP request is received, it is passed through a pipeline of BedSheet [Middleware](http://eggbox.fantomfactory.org/pods/afBedSheet/api/Middleware); this is a similar to [Java Servlet Filters](http://docs.oracle.com/javaee/5/api/javax/servlet/Filter.html). If the request reaches the end of the pipeline without being processed, a 404 is returned.

Middleware bundled with BedSheet include:

* `RequestLoggers`: For logging HTTP request / responses.
* `Routes` : Performs the standard [request routing](#requestRouting)


You can define your own middleware to address cross cutting concerns such as authentication and authorisation. See the FantomFactory article [Basic HTTP Authentication With BedSheet](http://www.alienfactory.co.uk/articles/basic-http-authentication-with-bedSheet) for working examples.

## <a name="errorProcessing"></a>Error Processing

When BedSheet catches an Err it scans through a list of contributed response objects to find one that can handle the Err. If no matching response object is found then the *default err response object* is used. This default response object displays BedSheet's extremely verbose Error 500 page. It displays (a shed load of) debugging information and is highly customisable:

![BedSheet's Verbose Err500 Page](http://eggbox.fantomfactory.org/pods/afBedSheet/doc/err500.png)

The BedSheet Err page is great for development, but not so great for production - stack traces tend to scare Joe Public! So note that in a production environment (see [IocEnv](http://eggbox.fantomfactory.org/pods/afIocEnv)) a simple HTTP status page is displayed instead.

> **ALIEN-AID:** BedSheet defaults to production mode, so to see the verbose error page you must switch to development mode.


The easiest way to do this is to set an environment variable called `ENV` with the value `development`. See [IocEnv](http://eggbox.fantomfactory.org/pods/afIocEnv) details.

To handle a specific Err, contribute a response object to `ErrResponses`:

    @Contribute { serviceType=ErrResponses# }
    Void contributeErrResponses(Configuration config) {
        config[ArgErr#] = MethodCall(MyErrHandler#process).toImmutableFunc
    }
    

Note that in the above example, `ArgErr` and all subclasses of `ArgErr` will be processed by `MyErrHandler.process()`. A contribution for just `Err` will act as a capture all and be used should a more precise match not be found.

You can also replace the default err response object:

    @Contribute { serviceType=ApplicationDefaults# }
    Void contributeApplicationDefaults(Configuration config) {
        config[BedSheetConfigIds.defaultErrResponse] = Text.fromHtml("<html><b>Oops!</b></html>")
    }
    

When processing an Err, note that the thrown `Err` is stored in `HttpRequest.stash`. It may be retrieved by handlers with the following:

    err := (Err) httpRequest.stash["afBedSheet.err"]

## <a name="httpStatusProcessing"></a>HTTP Status Processing

`HttpStatus` objects are handled by a [ResponseProcessor](http://eggbox.fantomfactory.org/pods/afBedSheet/api/ResponseProcessor) that selects a contributed response object that corresponds to the HTTP status code. If no specific response object is found then the *default http status response object* is used. This default response object displays BedSheet's HTTP Status Code page. This is what you see when you receive a `404 Not Found` error.

![BedSheet's 404 Status Page](http://eggbox.fantomfactory.org/pods/afBedSheet/doc/err404.png)

To set your own `404 Not Found` page contribute a response object to the `HttpStatusResponses` service with the status code `404`:

    @Contribute { serviceType=HttpStatusResponses# }
    Void contribute404Response(Configuration config) {
        config[404] = MethodCall(Error404Page#process).toImmutableFunc
    }
    

In the above example, all 404 status codes will be processed by `Error404Page.process()`.

To replace *all* status code responses, replace the default HTTP status response object:

    @Contribute { serviceType=ApplicationDefaults# }
    Void contributeApplicationDefaults(Configuration config) {
        config[BedSheetConfigIds.defaultHttpStatusResponse] = Text.fromHtml("<html>Error</html>")
    }
    

`HttpStatus` objects are stored in the `HttpRequest.stash` map and may be retrieved by handlers with the following:

    httpStatus := (HttpStatus) httpRequest.stash["afBedSheet.httpStatus"]

## Config Injection

BedSheet uses [IoC Config](http://eggbox.fantomfactory.org/pods/afIocConfig) to give injectable `@Config` values. `@Config` values are essentially a map of Str to immutable / constant values that may be set and overriden at application start up. (Consider config values to be immutable once the app has started).

BedSheet sets the initial config values by contributing to the `FactoryDefaults` service. An application may then override these values by contributing to the `ApplicationDefaults` service.

    @Contribute { serviceType=ApplicationDefaults# }
    Void contributeApplicationDefaults(Configuration conf) {
        ...
        conf["afBedSheet.errPrinter.noOfStackFrames"] = 100
        ...
    }
    

All BedSheet config keys are listed in [BedSheetConfigIds](http://eggbox.fantomfactory.org/pods/afBedSheet/api/BedSheetConfigIds) meaning the above can be more safely rewriten as:

    conf[BedSheetConfigIds.noOfStackFrames] = 100
    

Use the `@Config` facet to inject config values:

    @Config { id="afBedSheet.errPrinter.noOfStackFrames" }
    Int noOfStackFrames
    

The config mechanism is not just for BedSheet, you can use it too when creating 3rd Party libraries! Contributing initial values to `FactoryDefaults` gives users of your library an easy way to override your values.

## RESTful Services

BedSheet can be used to create RESTful applications. The general approach is to use `Routes` to define the URLs and HTTP methods that your app responds to.

For example, for a `POST` method:

    class RestAppModule {
        @Contribute { serviceType=Routes# }
        Void contributeRoutes(Configuration conf) {
            conf.add(Route(`/restAPI/*`, RestService#post, "POST"))
        }
    }
    

The routes then delegate to methods on a `RouteHandler` service:

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
    

## File Uploading

File uploading can be pretty horrendous in other languages, but here in Fantom land it's pretty easy.

First create your HTML, here's a form snippet:

    <form action="/uploadFile" method="POST" enctype="multipart/form-data">
        <input name="theFile" type="file" />
        <input type="submit" value="Upload File" />
    </form>
    

A `Route` should then service the `/uploadFile` URL:

    class RestAppModule {
        @Contribute { serviceType=Routes# }
        Void contributeRoutes(Configuration conf) {
            conf.add(Route(`/uploadFile`, UploadService#uploadFile, "POST"))
        }
    }
    

The `UploadService` uses `HttpRequest.parseMultiPartForm()` to gain access to the uploaded data and save it as a file:

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
    

## Request Logging

BedSheet has a hook for logging HTTP requests. Just implement [RequestLogger](http://eggbox.fantomfactory.org/pods/afBedSheet/api/RequestLogger) and contribute it to the `RequestLoggers` service. This service ensures the loggers are able to log what gets sent to the browser, without interruption from the error handling framework.

Example, this simple logger generates standard HTTP request log files in the [W3C Extended Log File Format](http://www.w3.org/TR/WD-logfile.html).

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
    

To enable, add the `W3CLogger` to the `RequestLoggers` service

    @Contribute { serviceType=RequestLoggers# }
    Void contributeRequestLoggers(Configuration config) {
        config.add(MyRequestLogger())
    }
    

The log files will then look something like the following, see [webmod::LogMod](https://fantom.org/doc/webmod/LogMod.html) for more details.

    2013-02-22 13:13:13 127.0.0.1 - GET /doc - 200 222 "Mozilla/5.0" "http://localhost/index"
    
    

### Default Logger

BedSheet ships with a basic default logger that times each request. To enable, turn on BedSheet debug logging. You can do this in code with:

    Log.get("afBedSheet").level = LogLevel.debug

Or you can enable it for the environment by adding the following to `%FAN_HOME%\etc\sys\log.props`

    afBedSheet = debug

Then you should see output like this in your console:

    [debug] [afBedSheet] GET  /about --------------------------------------------------> 200 (in 21ms)
    [debug] [afBedSheet] GET  /coldFeet/nx6lXQ==/css/website.min.css ------------------> 200 (in  6ms)
    [debug] [afBedSheet] GET  /pods ---------------------------------------------------> 200 (in 52ms)
    [debug] [afBedSheet] GET  /pods/whoops --------------------------------------------> 404 (in 28ms)
    

## Gzip

BedSheet compresses HTTP responses with gzip where it can for [HTTP optimisation](http://betterexplained.com/articles/how-to-optimize-your-site-with-gzip-compression/). Gzipping in BedSheet is highly configurable.

Gzip may be disabled for the entire web app by setting the following config property:

    @Contribute { serviceType=ApplicationDefaults# }
    Void contributeApplicationDefaults(Configuration config) {
        config[BedSheetConfigIds.gzipDisabled] = true
    }
    

Or Gzip can be disabled on a per request / response basis by calling:

    HttpResponse.disableGzip()
    

Text files gzip very well and yield high compression rates, but not everything should be gzipped. For example, JPG images are already compressed when gzip'ed often end up larger than the original! For this reason only [Mime Types](https://fantom.org/doc/sys/MimeType.html) contributed to the `GzipCompressible` service will be gzipped.

Most standard compressible types are already contributed to `GzipCompressible` including html, css, javascript, json, xml and other text responses. You may contribute your own with:

    @Contribute { serviceType=GzipCompressible# }
    Void configureGzipCompressible(Configuration config) {
        config[MimeType("text/funky")] = true
    }
    

Guaranteed that someone, somewhere is still using Internet Explorer 3.0 - or some other client that can't handle gzipped content from the server. As such, and as per [RFC 2616 HTTP1.1 Sec14.3](http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.3), the response is only gzipped if the appropriate HTTP request header was set.

Gzip is great when compressing large files, but if you've only got a few bytes to squash... then the compressed version is going to be bigger than the original - which kinda defeats the point compression! For that reason the response data must reach a minimum size / threshold before it gets gzipped. See [gzipThreshold](http://eggbox.fantomfactory.org/pods/afBedSheet/api/BedSheetConfigIds.gzipThreshold) for more details.

## Buffered Response

If a `Content-Length` header was not supplied then BedSheet attempts to calculate it by buffering `HttpResponse.out`. When the response stream is closed, it writes the `Content-Length` and pipes the buffer to the real HTTP response. This is part of [HTTP optimisation](http://stackoverflow.com/questions/2419281/content-length-header-versus-chunked-encoding).

Response buffering may be disabled on a per request / response basis by calling:

    HttpResponse.disableBuffering()
    

A threshold can be set, whereby if the buffer size exeeds that value, all content is streamed directly to the client. See [responseBufferThreshold](http://eggbox.fantomfactory.org/pods/afBedSheet/api/BedSheetConfigIds.responseBufferThreshold) for more details.

## <a name="developmentProxy"></a>Development Proxy

Never (manually) restart your app again!

Use the `-proxy` option when starting BedSheet to create a development Proxy and your app will auto re-start whenever a pod is updated:

    C:\> fan afBedSheet -port <port> -proxy <appModule>
    

The proxy sits on `(port)` and starts the real app on `(port+1)`, forwarding all requests to it.

Each time the web browser makes a request, it connects to the proxy which forwards it to the real web app.

    .                |---> Web App (port+1)
    Proxy (port) <-->|
                     |<--- Web Browser
    

On each request, the proxy scans the pod files in the Fantom environment, and should any of them be updated, it restarts the web application.

    .                |<--> RESTART
    Proxy (port) <-->|
                     |<--> Web Browser
    

Note that the proxy is intelligent enough to only scan those pods used by the web application. If need be, use the [-watchAllPods](http://eggbox.fantomfactory.org/pods/afBedSheet/api/Main) option to watch *all* pods.

A problem other web frameworks (*cough* *draft*) suffer from is that, when the proxy dies, your real web app is left hanging around; requiring you to manually kill it. Which can be both confusing and annoying.

    .                |<--> Web App (port+1)
                 ??? |
                     |<--> Web Browser
    

BedSheet applications go a step further and, should it be started in proxy mode, it pings the proxy every second to stay alive. Should the proxy not respond, the web app kills itself.

See [proxyPingInterval](http://eggbox.fantomfactory.org/pods/afBedSheet/api/BedSheetConfigIds.proxyPingInterval) for more details.

## Wisp Integration

To some, BedSheet may look like a behemoth web framework, but it is in fact just a standard Fantom [WebMod](https://fantom.org/doc/web/WebMod.html). This means it can be plugged into a [Wisp](https://fantom.org/doc/wisp/index.html) application along side other all the other standard [webmods](https://fantom.org/doc/webmod/index.html). Just create an instance of [BedSheetWebMod](http://eggbox.fantomfactory.org/pods/afBedSheet/api/BedSheetWebMod) and pass it to Wisp like any other.

For example, the following Wisp application places BedSheet under the path `poo/`.

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
        Void contributeRoutes(Configuration conf) {
            conf.add(Route(`/***`, Text.fromPlain("Hello Mum!")))
        }
    }
    

When run, a request to `http://localhost:8069/` will return a Wisp 404 and any request to `http://localhost:8069/poo/*` will invoke BedSheet and return `Hello Mum!`.

When running BedSheet under a non-root path, be sure to transform all link hrefs with [BedSheetServer.toClientUrl()](http://eggbox.fantomfactory.org/pods/afBedSheet/api/BedSheetServer.toClientUrl) to ensure the extra path info is added. Similarly, ensure asset URLs are retrieved from the [FileHandler](http://eggbox.fantomfactory.org/pods/afBedSheet/api/FileHandler) service.

Note that mulitple BedSheet instances may be run side by side in the same Wisp application.

## SkySpark Integration

BedSheet can also be seemlessly run as [SkySpark Web Extension](https://skyfoundry.com/doc/docSkySpark/Exts#extClass)

Following is a SkySpark Web [Ext](https://skyfoundry.com/doc/skyarcd/Ext) that delegates all web requests to BedSheet.

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
            registry.activeScope.createChild("httpRequest") {
                // this is the actual call to BedSheet!
                pipeline.service
            }
        }
    
        override Void onStop() {
            registry.shutdown
        }
    }
    

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

## Hints

All route handlers and processors are built by [IoC](http://eggbox.fantomfactory.org/pods/afIoc) so feel free to `@Inject` DAOs and other services.

BedSheet itself is built with [IoC](http://eggbox.fantomfactory.org/pods/afIoc) so look at the [BedSheet Source](https://bitbucket.org/AlienFactory/afbedsheet/src) for [IoC](http://eggbox.fantomfactory.org/pods/afIoc) examples.

Even if your route handlers aren't services, if they're `const` classes, they're cached by BedSheet and reused on every request.

