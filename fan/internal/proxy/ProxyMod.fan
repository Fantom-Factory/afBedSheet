using concurrent::Actor
using web::WebClient
using web::WebMod

// TODO: Move the app-restarting into separate thread which checks every X secs
internal const class ProxyMod : WebMod {
	private const static Log log := Utils.getLog(ProxyMod#)

	const Int proxyPort
	const Int appPort
	const AppRestarter restarter
	
	new make(Str appModule, Int proxyPort, Bool noTransDeps, Str? env) {
		this.proxyPort 	= proxyPort
		this.appPort 	= proxyPort + 1
		this.restarter 	= AppRestarter(appModule, appPort, proxyPort, noTransDeps, env)
	}

	override Void onStart() {
		log.info(BsLogMsgs.proxyModStarting(proxyPort))
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

		// proxy request
		c := WebClient()
		c.followRedirects = false
		c.reqUri = "http://localhost:${appPort}${req.uri.relToAuth}".toUri
		c.reqMethod = req.method
		req.headers.each |v,k| {
			if (k == "Host") return
			c.reqHeaders[k] = v
		}
		c.writeReq

		is100Continue := c.reqHeaders["Expect"] == "100-continue"

		if (req.method == "POST" && ! is100Continue)
			c.reqOut.writeBuf(req.in.readAllBuf).flush

		// proxy response
		c.readRes

		if (is100Continue && c.resCode == 100) {
			c.reqOut.writeBuf(req.in.readAllBuf).flush
			c.readRes // final response after the 100continue
		}

		res.statusCode = c.resCode
		c.resHeaders.each |v,k| { res.headers[k] = v }
		if (c.resHeaders["Content-Type"]	!= null ||
			c.resHeaders["Content-Length"] 	!= null)
			res.out.writeBuf(c.resIn.readAllBuf).flush
		c.close
	}
}
