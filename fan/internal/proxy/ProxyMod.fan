using concurrent::Actor
using web::WebClient
using web::WebMod

// todo: Move the app-restarting into separate thread which checks every X secs
//       actually, don't. It takes too much processor time to re-start the app.
internal const class ProxyMod : WebMod {
	private const static Log log := Utils.getLog(ProxyMod#)

	const Int 			proxyPort
	const Int 			appPort
	const AppRestarter	restarter
	const Version 		webVer		:= Pod.find("web").version
	
	new make(Str appModule, Int proxyPort, Bool noTransDeps, Str? env) {
		this.proxyPort 	= proxyPort
		this.appPort 	= proxyPort + 1
		this.restarter 	= AppRestarter(appModule, appPort, proxyPort, noTransDeps, env)
	}

	override Void onStart() {
		log.info(BsLogMsgs.proxyMod_starting(proxyPort))
		restarter.initialise
	}
	
	override Void onService() {
		if (req.modRel == BsConstants.pingUrl) {
			mimeType := MimeType("text/plain; charset=$Charset.utf8.name")
			res.headers["Content-Type"] = mimeType.toStr
			res.out.print("OK")
			res.out.close
			return
		}

		// if restarted, wait for wisp to start up
		if (restarter.checkPods)
			Actor.sleep(1.5sec)

		// 13-Jan-2013
		// Safari seems to have trouble creating seesion cookie
		// with proxy server - create session here as a workaround
		dummy := req.session

		c := WebClient()
		c.reqHeaders.clear
		c.followRedirects = false
		c.reqUri = "http://localhost:${appPort}${req.uri.relToAuth}".toUri
		c.reqMethod = req.method
		req.headers.each |v, k| {
			if (k != "Host")	// don't mess with the Hoff! Err, I mean host.
				c.reqHeaders[k] = v
		}
		c.writeReq

		is100Continue := c.reqHeaders["Expect"] == "100-continue"

		if (req.method == "POST" && ! is100Continue)
			c.reqOut.writeBuf(req.in.readAllBuf).flush

		c.readRes

		if (is100Continue && c.resCode == 100) {
			c.reqOut.writeBuf(req.in.readAllBuf).flush
			c.readRes // final response after the 100continue
		}

		regzip := false
		redeflate := false
		res.statusCode = c.resCode
		c.resHeaders.each |v, k| {
			if (k == "Content-Encoding") {
				if (v.trim == "gzip")
					regzip = true
				if (v.trim == "deflate")
					redeflate = true
			}
			res.headers[k] = v
		}
		
		if (c.resHeaders["Content-Type"]	!= null ||
			c.resHeaders["Content-Length"] 	!= null) {
			resBuf := c.resIn.readAllBuf
			resOut := (OutStream) res.out

			// because v1.0.67 auto de-gzips the response, we need to re-gzip it on the way out
			// I'm not overly happy with this but it's ingrained deep in web::WebUtil.makeContentInStream()
			if (webVer >= Version("1.0.67")) {
				if (regzip)
					resOut = Zip.gzipOutStream(resOut)
				if (redeflate)
					resOut = Zip.deflateOutStream(resOut)
			}
				
			resOut.writeBuf(resBuf).flush.close
		}
		c.close
	}
}
