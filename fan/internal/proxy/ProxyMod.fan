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
	const Duration		startupWait
	
	new make(BedSheetBuilder bob, Int proxyPort, Bool watchAllPods) {
		this.proxyPort 	= proxyPort
		this.appPort 	= proxyPort + 1
		this.startupWait= (bob.options["afBedSheet.proxy.startupWait"] as Duration) ?: 1sec
		bob.options[BsConstants.meta_proxyPort] = this.proxyPort
		bob.options[BsConstants.meta_appPort] 	= this.appPort
		bob.options[BsConstants.meta_pingProxy] = true
		this.restarter 	= AppRestarter(bob, appPort, watchAllPods)
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
			Actor.sleep(startupWait)

		c := (WebClient?) null
		try {
			c = writeReq()
			
		} catch (IOErr ioe) {
			// if we can't connect to the website, it may be down / not have started
			// (e.g. if counldn't connect to MongoDB) so force a restart
			log.info(BsLogMsgs.proxyMod_forceRestart)
			restarter.forceRestart
			Actor.sleep(startupWait)
			c = writeReq()
		}

		if (req.headers.containsKey("Content-Type") || req.headers.containsKey("Content-Length"))
			c.reqOut.writeBuf(req.in.readAllBuf).flush

		c.readRes

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
		
		if (c.resHeaders.containsKey("Content-Type") ||	c.resHeaders.containsKey("Content-Length")) {
			resBuf := c.resIn.readAllBuf
			resOut := (OutStream) res.out

			// because v1.0.67 auto de-gzips the response, we need to re-gzip it on the way out
			// I'm not overly happy with this but it's ingrained deep in web::WebUtil.makeContentInStream()
			if (regzip)
				resOut = Zip.gzipOutStream(resOut)
			if (redeflate)
				resOut = Zip.deflateOutStream(resOut)
				
			try
				resOut.writeBuf(resBuf)
			catch (IOErr ioe)
				// we don't care for the stacktrace, so just log the msg. It's usually something like:
				//  java.net.SocketException: Software caused connection abort: socket write error
				log.err("Error processing: ${req.uri.relToAuth}\n  ${ioe.msg}")
			finally
				resOut.flush.close
		}

		c.close
	}
	
	private WebClient writeReq() {
		c := WebClient()
		try {
			c.reqHeaders.clear
			c.followRedirects = false
			c.reqUri = "http://localhost:${appPort}${req.uri.relToAuth}".toUri
			c.reqMethod = req.method
			req.headers.each |v, k| {
				if (!k.equalsIgnoreCase("Host"))	// don't mess with the Hoff! Err, I mean host.
					c.reqHeaders[k] = v
			}
			
			/// sys::IOErr: java.net.ConnectException: Connection refused: connect
			c.writeReq
			return c
		} catch (Err err) {
			c.close
			throw err
		}
	}
}
